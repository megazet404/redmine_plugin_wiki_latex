require 'digest/sha2'
require 'tempfile'

module WikiLatexHelper

  DIR = File.join(Rails.root, 'tmp', 'wiki_latex')

  def self.rm_rf(path)
    FileUtils.rm_r(path, force: true, secure: true)
  end

  class Macro
    def initialize(full_source)
      # Get rid of nasty Windows line endings.
      full_source.gsub!(/\r\n?/, "\n")

      # Do we really need this processing???
      full_source.gsub!(/<br \/>/,"")
      full_source.gsub!(/<\/?p>/,"")
      full_source.gsub!(/<\/?div>/,"")

      # Do we really need this processing??????
      full_source.gsub!('\\\\','\\')

      if full_source.include?  ('|||||')
        ary = full_source.split('|||||')
        preamble = ary[0]
        source   = ary[1]
      else
        preamble = ""
        source   = full_source
      end

      name = Digest::SHA256.hexdigest(preamble+source)

      @latex = WikiLatex.find_by_image_id(name)
      if !@latex
        @latex = WikiLatex.new(:source => source, :image_id => name, :preamble => preamble)
        @latex.save
      end
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

    def render_block(view, page)
      content =  ""
      content += render_header  (view)
      content += render_template(view, "macro_block", {:image_id => @latex.image_id, :preamble => @latex.preamble, :source => @latex.source, :page => page})
      content.html_safe
    end
  end
end
