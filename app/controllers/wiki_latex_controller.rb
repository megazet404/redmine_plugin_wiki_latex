class WikiLatexController < ApplicationController
  class LatexProcessor
    def self.make_png(basefilepath)
      LatexProcessor.new(basefilepath).make_png()
    end

    def self.quote(str)
      (str == "" ? "" : '"' + str + '"')
    end

    def initialize(basefilepath)
      @basefilepath = basefilepath
      @dir          = File.dirname (@basefilepath)
      @name         = File.basename(@basefilepath)
      @dir_q        = LatexProcessor.quote(@dir)

      @latex = WikiLatex.find_by_image_id(@name)
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

    def make_tex
      FileUtils.mkdir_p(@dir)

      File.open(@basefilepath+".tex", 'wb') do |f|
        f.print('\input{../../plugins/wiki_latex/assets/latex/header.tex}', "\n")
        f.print(@latex.preamble, "\n") if !@latex.preamble.empty?
        f.print('\input{../../plugins/wiki_latex/assets/latex/header2.tex}', "\n")
        f.print(@latex.source  , "\n") if !@latex.source.empty?
        f.print('\input{../../plugins/wiki_latex/assets/latex/footer.tex}', "\n")
      end
    end

    def run_latex(tool, ext)
      make_tex

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

      run_cmd("cd #{@dir_q} && #{PATH_Q}#{tool} #{opts} #{@name}.tex")
      check_file("#{@basefilepath}.#{ext}")
    end

    def make_pdf
      run_latex("pdflatex", "pdf")
    end

    def make_dvi
      run_latex("latex", "dvi")
    end

  public
    def make_png
      filepath = "#{@basefilepath}.png"

      return filepath if File.exists?(filepath)

      begin
        make_tex

        if WikiLatexConfig::Png::GRAPHICS_SUPPORT
          make_pdf
          run_cmd("cd #{@dir_q} && #{PATH_Q}pdftops -eps #{@name}.pdf")
          run_cmd("cd #{@dir_q} && #{PATH_Q}convert -density 100 #{@name}.eps #{@name}.png")
        else
          make_dvi
          run_cmd("cd #{@dir_q} && #{PATH_Q}dvipng -T tight -bg Transparent #{@name}.dvi -q -o #{@name}.png")
        end
        check_file(filepath)
      ensure
        ['tex','pdf','eps','dvi','log','aux'].each do |ext|
          WikiLatexHelper::suppress { WikiLatexHelper::rm_rf("#{@basefilepath}.#{ext}") }
        end
      end
      return filepath
    end
  end

  def image
    name = params[:image_id]
    basefilepath = File.join(WikiLatexHelper::DIR, name)
    image_file = "#{basefilepath}.png"

    if (!File.exists?(image_file))
    	LatexProcessor.make_png(basefilepath)
    end
    if (File.exists?(image_file))
      #render :file => image_file, :layout => false, :content_type => 'image/png'
      f = open(image_file, "rb") { |io| io.read }
      send_data f, :type => 'image/png',:disposition => 'inline'

    else
    	render_404
    end
    rescue ActiveRecord::RecordNotFound
      render_404
  end
end
