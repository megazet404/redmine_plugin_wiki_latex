require 'digest/sha2'

module WikiLatexHelper

  DIR = File.join(Rails.root, 'tmp', 'wiki_latex')

  def self.rm_rf(path)
    FileUtils.rm_r(path, force: true, secure: true)
  end

  def self.suppress(&block) # Suppress exception.
    begin
      block.call
    rescue
      # Igore exception.
    end
  end

  def self.lock(filepath, &block)
    begin
      FileUtils.mkdir_p(File.dirname(filepath))
      File.open(filepath, 'wb') do |lock|
        lock.flock(File::LOCK_EX)
        block.call
      end
    ensure
      # Ignore error if file can't be delete because it is locked by other process.
      suppress do
        # Deleting lock seems to be a bad idea. Linux allows to delete file even
        # if it is locked by other process. If we delete file locked by one process
        # then other processes won't see this lock and will act as if there is no lock.
        # Though this problem is not applicable to Windows.
        #File.unlink(filepath)
      end
    end
  end

  def self.make_tex(image_id, preamble, source, locked = false)
    basefilepath = File.join(DIR, image_id)
    filepath  = "#{basefilepath}.tex"

    make = -> do
      return if File.exist?(filepath)

      FileUtils.mkdir_p(DIR)

      File.open(filepath, 'wb') do |f|
        f.print('\input{../../plugins/wiki_latex/assets/latex/header.tex}', "\n")
        f.print(preamble, "\n") if !preamble.empty?
        f.print('\input{../../plugins/wiki_latex/assets/latex/header2.tex}', "\n")
        f.print(source  , "\n") if !source.empty?
        f.print('\input{../../plugins/wiki_latex/assets/latex/footer.tex}', "\n")
      end
    end

    if locked
      return if File.exist?(filepath)
      lock("#{basefilepath}.lock") do
        make.call
      end
    else
      make.call
    end
  end

  def self.clear_db
   #WikiLatex.destroy_all # It's too slow.
    WikiLatex.delete_all
  end

  class Macro
    def self.render_inline(source, view)
      Macro.new(:source => source).render_inline(view)
    end

    def self.render_block(project, page, view)
      Macro.new(:project => project, :page => page).render_block(view)
    end

    def initialize(params)
      # Retrieve full_source from params.
      begin
        if (params.key?(:source))
          full_source = params[:source]
        else
          @page = Wiki.find_page(params[:page], :project => params[:project])
          raise 'page not found' if @page.nil? || !User.current.allowed_to?(:view_wiki_pages, @page.wiki.project)

          @included_wiki_pages ||= []
          raise 'circular inclusion detected' if @included_wiki_pages.include?(@page.title)
          @included_wiki_pages << @page.title
          @included_wiki_pages.pop
          full_source = @page.content.text
        end
      end

      # Process full_source.
      begin
        # Get rid of nasty Windows line endings.
        full_source.gsub!(/\r\n?/, "\n")

        # Do we really need this processing???
        full_source.gsub!(/<br \/>/,"")
        full_source.gsub!(/<\/?p>/,"")
        full_source.gsub!(/<\/?div>/,"")

        # Do we really need this processing??????
        full_source.gsub!('\\\\','\\')
      end

      # Split full_source.
      begin
        if full_source.include?  ('|||||')
          ary = full_source.split('|||||')
          @preamble = ary[0]
          @source   = ary[1]
        else
          @preamble = ""
          @source   = full_source
        end
      end

      # Get image ID from full_source.
      begin
        @image_id = Digest::SHA256.hexdigest(full_source)

        # We need to encode string to default encoding, because the function above generates binary
        # string, and some DBMSes (SQLite for example) do not work well with binary strings.
        @image_id.encode!()
      end

      # Save source.
      begin
        if WikiLatexConfig::STORE_LATEX_IN_DB
          if !WikiLatex.find_by_image_id(@image_id)
            WikiLatex.new(:image_id => @image_id, :preamble => @preamble, :source => @source).save
          end
        else
          WikiLatexHelper::make_tex(@image_id, @preamble, @source, true)
        end
      end
    end

  private
    def wa_embed_inline(view)
      # Link CSS to the page if it is not linked yet.
      if !view.instance_variable_get("@wiki_latex_css_linked")
        view.content_for :header_tags do
          view.stylesheet_link_tag "wiki_latex.css", :plugin => "wiki_latex", :media => :all
        end
        view.instance_variable_set("@wiki_latex_css_linked", true)
      end
      # Insert latex image to the page.
      "<img class='latexinline' src='#{view.url_for(:controller => 'wiki_latex', :action => 'image_svg', :image_id => @image_id)}' alt='#{@source}' />"
        .html_safe
    end

    def render_template(view, template, locals)
      view.controller.render_to_string(:template => "wiki_latex/#{template}", :layout => false, :locals => locals)
    end

    def render_header(view)
      render_template(view, "header", {:view => view})
    end

  public
    def render_inline(view)
      if WikiLatexConfig::Wa::DIRECT_EMBED
        return wa_embed_inline(view)
      end

      content =  ""
      content += render_header  (view)
      content += render_template(view, "macro_inline", {:image_id => @image_id, :preamble => @preamble, :source => @source})
      content.html_safe
    end

    def render_block(view)
      if WikiLatexConfig::Wa::DIRECT_EMBED
        raise "macro is unsupported"
      end

      content =  ""
      content += render_header  (view)
      content += render_template(view, "macro_block", {:image_id => @image_id, :preamble => @preamble, :source => @source, :page => @page})
      content.html_safe
    end
  end
end
