class WikiLatexController < ApplicationController
  class LatexProcessor
    def self.make_png(basefilename)
      LatexProcessor.new(basefilename).make_png()
    end

    PATH = (WikiLatexConfig::TOOLS_PATH == "" ? "" : File.join(WikiLatexConfig::TOOLS_PATH, ""))

    def initialize(basefilename)
      @basefilename = basefilename
      @dir          = File.dirname (@basefilename)
      @name         = File.basename(@basefilename)

      @latex = WikiLatex.find_by_image_id(@name)
    end

    def make_png()
      begin
        Dir.mkdir(@dir)
      rescue
      end
      temp_latex = File.open(@basefilename+".tex",'wb')
      temp_latex.print('\input{../../plugins/wiki_latex/assets/latex/header.tex}', "\n")
      temp_latex.print(@latex.preamble.gsub('\\\\','\\').gsub(/\r\n?/, "\n"), "\n")
      temp_latex.print('\input{../../plugins/wiki_latex/assets/latex/header2.tex}', "\n")
      temp_latex.print(@latex.source.gsub('\\\\','\\').gsub(/\r\n?/, "\n"), "\n")
      temp_latex.print('\input{../../plugins/wiki_latex/assets/latex/footer.tex}', "\n")
      temp_latex.flush
      temp_latex.close

      if WikiLatexConfig::Png::GRAPHICS_SUPPORT
        system("cd #{@dir} && #{PATH}pdflatex --interaction=nonstopmode #{@name}.tex")
        system("cd #{@dir} && #{PATH}pdftops -eps #{@name}.pdf")
        system("cd #{@dir} && #{PATH}convert -density 100 #{@name}.eps #{@name}.png")
      else
        system("cd #{@dir} && #{PATH}latex --interaction=nonstopmode #{@name}.tex")
        system("cd #{@dir} && #{PATH}dvipng -T tight -bg Transparent #{@name}.dvi -o #{@name}.png")
      end
      ['tex','pdf','eps','dvi', 'log','aux'].each do |ext|
        if File.exists?(@basefilename+"."+ext)
          File.unlink(@basefilename+"."+ext)
        end
      end
    end
  end

  def image
    name = params[:image_id]
    basefilename = File.join(WikiLatexHelper::DIR, name)
    if name != "error"
	image_file = "#{basefilename}.png"
    else
	image_file = File.join([Rails.root, 'public', 'plugin_assets', 'wiki_latex', 'images', name+".png"])
    end

    if (!File.exists?(image_file))
    	LatexProcessor.make_png(basefilename)
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
