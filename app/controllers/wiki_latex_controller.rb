class WikiLatexController < ApplicationController
private
  class ErrorNotFound < StandardError; end
  class ErrorBadTex   < StandardError; end

  class LatexProcessor
    def self.quote(str)
      (str == "" ? "" : '"' + str + '"')
    end

    def initialize(basefilepath)
      @basefilepath = basefilepath
      @dir_q        = LatexProcessor.quote(File.dirname (@basefilepath))
      @name         =                      File.basename(@basefilepath)
    end

  private
    PATH_Q = quote(WikiLatexConfig::TOOLS_PATH == "" ? "" : File.join(WikiLatexConfig::TOOLS_PATH, ""))

    def run_cmd(cmd)
      success = system(cmd)
      raise "failed to run: #{cmd}" if !success
    end

    def check_file(filepath)
      raise "file was not created: #{filepath}" if !File.exists?(filepath)
    end

    def run_latex(tool, ext)
      # Compose command line options.
      opts = ""
      begin
        if WikiLatexConfig::LATEX_NO_OUTPUT
          # Do not request user input, do default actions on errors.
          # Do not output any messages to log.
          opts += " -interaction=batchmode"
        else
          # The same as batchmode, but messages are outputted.
          opts += " -interaction=nonstopmode"
        end

        if WikiLatexConfig::LATEX_QUIET
          # Print only errors to logs.
          opts += " -quiet"
        end

        # If there are any errors in LaTeX source then 'latex' exits with error code
        # even if the errors were automatically fixed. We check for error codes,
        # so it doesn't make sense for us to continue after error.
        opts += " -halt-on-error"
      end

      begin
        run_cmd("cd #{@dir_q} && #{PATH_Q}#{tool} #{opts} #{@name}.tex")
        check_file("#{@basefilepath}.#{ext}")
      rescue
        raise ErrorBadTex
      end
    end

    def make_pdf
      run_latex("pdflatex", "pdf")
    end

    def make_dvi
      run_latex("latex", "dvi")
    end

    def make_png_via_pdf
      # Make PDF from LaTeX source code.
      make_pdf

      # Convert PDF to EPS.
      run_cmd("cd #{@dir_q} && #{PATH_Q}pdftops -eps #{@name}.pdf")

      # Zoom options.
      opts = " -density " + (WikiLatexConfig::ZOOM_FACTOR * 100.0).round.to_s

      # Convert EPS to PNG.
      run_cmd("cd #{@dir_q} && #{PATH_Q}convert #{opts} #{@name}.eps #{@name}.png")
    end

    def make_png_via_dvi
      make_dvi

      # Compose command line options.
      opts = ""
      begin
        if WikiLatexConfig::ZOOM_FACTOR != 1
          # Zoom image.
          opts += " -D " + (WikiLatexConfig::ZOOM_FACTOR * 100.0).round.to_s
        end

        # Crop PNG to contain only pixels with TeX content.
        opts += " -T tight"

        # Make background transparent.
        opts += " -bg Transparent"

        # Print only errors to logs.
        opts += " -q"
      end

      run_cmd("cd #{@dir_q} && #{PATH_Q}dvipng #{opts} #{@name}.dvi -o #{@name}.png")
    end

    def cleanup
      ['pdf','eps','dvi','log','aux','tmp'].each do |ext|
        WikiLatexHelper::suppress { WikiLatexHelper::rm_rf("#{@basefilepath}.#{ext}") }
      end
    end

  public
    def make_png
      begin
        if WikiLatexConfig::Png::GRAPHICS_SUPPORT
          make_png_via_pdf
        else
          make_png_via_dvi
        end
        check_file("#{@basefilepath}.png")
      ensure
        cleanup
      end
    end

    def make_svgz
      begin
        make_dvi

        # Compose command line options.
        opts = ""
        begin
          # Embed font or not.
          # Unfortunately '-f svg' is broken, so we use '-f woff2'. 'ah' is auto hinting.
          opts += (WikiLatexConfig::Svg::EMBED_FONT ? " -f woff2,ah" : " -n")

          if WikiLatexConfig::ZOOM_FACTOR != 1
            # Zoom image.
            opts += (WikiLatexConfig::Svg::ZOOM_METHOD == "Z" ? " -Z" : " -c") + WikiLatexConfig::ZOOM_FACTOR.to_s
          end

          # More precise bounding box calculation. TeX content may be clipped without this option.
          opts += " -e"

          # Draw transparent border around TeX content.
          opts += " -b" + WikiLatexConfig::Svg::BORDER.to_s

          # Gzip resulting SVG to save disk space.
          opts += " -z"

          # Print only errors and warnings to logs.
          opts += " -v3"

          if WikiLatexConfig::Svg::WA_MAKE_TMP
            # Create temporary directory for temporary files produced by 'dvisvgm'.
            FileUtils.mkdir_p("#{@basefilepath}.tmp")
            opts += " --tmpdir=#{@basefilepath}.tmp"
          end
        end

        run_cmd("cd #{@dir_q} && #{PATH_Q}dvisvgm #{opts} #{@name}.dvi -o #{@name}.svg.gz")
        check_file("#{@basefilepath}.svg.gz")
      ensure
        cleanup
      end
    end

    def self.make_png(basefilepath)
      LatexProcessor.new(basefilepath).make_png()
    end

    def self.make_svgz(basefilepath)
      LatexProcessor.new(basefilepath).make_svgz()
    end
  end

  def send_file(filepath, opts)
    # We need this function as workaround. If we use standard 'send_file' method, then .gz extension
    # of svg.gz file is leaked to browser via HTTP headers. And when user tries to save file, it is
    # saved as .gz file instead of .svg.
    data = File.open(filepath, "rb") { |f| f.read }
    send_data data, opts
  end

  def send_png(filepath)
    send_file filepath, :type => 'image/png', :disposition => 'inline'
  end

  def send_svgz(filepath)
    opts = {:type => 'image/svg+xml', :disposition => 'inline'}
    if WikiLatexConfig::Svg::CLIENT_SIDE_DECOMPRESSION
      response.headers["Content-Encoding"] = "gzip"
      send_file filepath, opts
    else
      data = Zlib::GzipReader.open(filepath) { |f| f.read }
      send_data data, opts
    end
  end

  def render_bad_tex
    filepath = File.join(Rails.root, 'public', 'plugin_assets', 'wiki_latex', 'images', "error.png")
    return render_404 if !File.exists?(filepath)

    send_png filepath
  end

  def handle_error
    begin
      raise
    rescue ErrorNotFound
      render_404
    rescue ErrorBadTex
      render_bad_tex
    end
  end

  def make_from_tex(ext, &block)
    image_id       = params[:image_id]
    basefilepath   = File.join(WikiLatexHelper::DIR, image_id)
    image_filepath = "#{basefilepath}.#{ext}"
    tex_filepath   = "#{basefilepath}.tex"

    return image_filepath if File.exists?(image_filepath)

    if WikiLatexConfig::STORE_LATEX_IN_DB
      latex = WikiLatex.find_by_image_id(image_id)
      raise ErrorNotFound if !latex
    else
      raise ErrorNotFound if !File.exists?(tex_filepath)
    end

    WikiLatexHelper::lock("#{basefilepath}.lock") do
      # Check again under lock.
      return image_filepath if File.exists?(image_filepath)

      if latex
        WikiLatexHelper::make_tex(basefilepath, latex.preamble, latex.source)
      end

      begin
        block.call(basefilepath)
      rescue
        # Remove possiblly buggy tex.
        WikiLatexHelper::suppress { WikiLatexHelper::rm_rf(tex_filepath) }
        raise
      end
    end

    return image_filepath
  end

public
  def image_png
    begin
      filepath = make_from_tex("png") do |basefilepath|
        LatexProcessor.make_png(basefilepath)
      end
      send_png(filepath)
    rescue
      handle_error
    end
  end

  def image_svg
    begin
      filepath = make_from_tex("svg.gz") do |basefilepath|
        LatexProcessor.make_svgz(basefilepath)
      end
      send_svgz(filepath)
    rescue
      handle_error
    end
  end
end
