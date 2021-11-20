require 'digest/sha2'
require 'tempfile'

module WikiLatexHelper

  DIR = File.join(Rails.root, 'tmp', 'wiki_latex')

  def self.rm_rf(path)
    FileUtils.rm_r(path, force: true, secure: true)
  end

  class Macro
    def self.render_inline(source, view)
      Macro.new(:source => source).render_inline(view)
    end

    def self.render_block(project, page, view)
      Macro.new(:project => project, :page => page).render_block(view)
    end

    def initialize(params)
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

      # Get rid of nasty Windows line endings.
      full_source.gsub!(/\r\n?/, "\n")

      # Do we really need this processing???
      full_source.gsub!(/<br \/>/,"")
      full_source.gsub!(/<\/?p>/,"")
      full_source.gsub!(/<\/?div>/,"")

      # Do we really need this processing??????
      full_source.gsub!('\\\\','\\')

      image_id = Digest::SHA256.hexdigest(full_source)

      @latex = WikiLatex.find_by_image_id(image_id)
      if (@latex)
        return
      end

      if full_source.include?  ('|||||')
        ary = full_source.split('|||||')
        preamble = ary[0]
        source   = ary[1]
      else
        preamble = ""
        source   = full_source
      end

      @latex = WikiLatex.new(:image_id => image_id, :preamble => preamble, :source => source)
      @latex.save
    end

  private
    def render_template(view, template, locals)
      view.controller.render_to_string(:template => "wiki_latex/#{template}", :layout => false, :locals => locals)
    end

    def render_header(view)
      render_template(view, "header", {:view => view})
    end

  public
    def render_inline(view)
      content =  ""
      content += render_header  (view)
      content += render_template(view, "macro_inline", {:image_id => @latex.image_id, :preamble => @latex.preamble, :source => @latex.source})
      content.html_safe
    end

    def render_block(view)
      content =  ""
      content += render_header  (view)
      content += render_template(view, "macro_block", {:image_id => @latex.image_id, :preamble => @latex.preamble, :source => @latex.source, :page => @page})
      content.html_safe
    end
  end
end
