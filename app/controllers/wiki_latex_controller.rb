class WikiLatexController < ApplicationController

  PATH = (WikiLatexConfig::TEX_TOOLS_PATH == "" ? "" : File.join(WikiLatexConfig::TEX_TOOLS_PATH, ""))

  def image
    @latex = WikiLatex.find_by_image_id(params[:image_id])
    @name = params[:image_id]
    if @name != "error"
	image_file = File.join([Rails.root, 'tmp', 'wiki_latex', @name+".png"])
    else
	image_file = File.join([Rails.root, 'public', 'plugin_assets', 'wiki_latex', 'images', @name+".png"])
    end

    if (!File.exists?(image_file))
    	render_image
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

private
  def render_image
    dir = File.join([Rails.root, 'tmp', 'wiki_latex'])
    begin
      Dir.mkdir(dir)
    rescue
    end
    basefilename = File.join([dir,@name])
    temp_latex = File.open(basefilename+".tex",'w')
    temp_latex.puts('\input{../../plugins/wiki_latex/assets/latex/header.tex}')
    temp_latex.puts @latex.preamble.gsub('\\\\','\\')
    temp_latex.puts('\input{../../plugins/wiki_latex/assets/latex/header2.tex}')
    temp_latex.puts @latex.source.gsub('\\\\','\\')
    temp_latex.puts('\input{../../plugins/wiki_latex/assets/latex/footer.tex}')
    temp_latex.flush
    temp_latex.close

    system("cd "+dir+" && "+PATH+"pdflatex --interaction=nonstopmode "+@name+".tex 2> /dev/null > /dev/null")
    system("cd "+dir+" && "+PATH+"pdftops -eps "+@name+".pdf")
    system("cd "+dir+" && "+PATH+"convert -density 100 "+@name+".eps "+@name+".png")
    ['tex','pdf','log','aux','eps'].each do |ext|
    if File.exists?(basefilename+"."+ext)
        File.unlink(basefilename+"."+ext)
	end
    end
  end

end

