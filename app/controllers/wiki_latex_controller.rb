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

    PATH_Q = quote(WikiLatexConfig::TOOLS_PATH == "" ? "" : File.join(WikiLatexConfig::TOOLS_PATH, ""))

    def make_png()
      begin
        Dir.mkdir(@dir)
      rescue
      end
      temp_latex = File.open(@basefilepath+".tex",'wb')
      temp_latex.print('\input{../../plugins/wiki_latex/assets/latex/header.tex}', "\n")
      temp_latex.print(@latex.preamble, "\n")
      temp_latex.print('\input{../../plugins/wiki_latex/assets/latex/header2.tex}', "\n")
      temp_latex.print(@latex.source, "\n")
      temp_latex.print('\input{../../plugins/wiki_latex/assets/latex/footer.tex}', "\n")
      temp_latex.flush
      temp_latex.close

      if WikiLatexConfig::Png::GRAPHICS_SUPPORT
        system("cd #{@dir_q} && #{PATH_Q}pdflatex --interaction=nonstopmode #{@name}.tex")
        system("cd #{@dir_q} && #{PATH_Q}pdftops -eps #{@name}.pdf")
        system("cd #{@dir_q} && #{PATH_Q}convert -density 100 #{@name}.eps #{@name}.png")
      else
        system("cd #{@dir_q} && #{PATH_Q}latex --interaction=nonstopmode #{@name}.tex")
        system("cd #{@dir_q} && #{PATH_Q}dvipng -T tight -bg Transparent #{@name}.dvi -o #{@name}.png")
      end
      ['tex','pdf','eps','dvi', 'log','aux'].each do |ext|
        if File.exists?(@basefilepath+"."+ext)
          File.unlink(@basefilepath+"."+ext)
        end
      end
    end
  end

  def image
    name = params[:image_id]
    basefilepath = File.join(WikiLatexHelper::DIR, name)
    if name != "error"
	image_file = "#{basefilepath}.png"
    else
	image_file = File.join([Rails.root, 'public', 'plugin_assets', 'wiki_latex', 'images', name+".png"])
    end

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
