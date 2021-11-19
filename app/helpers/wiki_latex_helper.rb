require 'digest/sha2'
require 'tempfile'

module WikiLatexHelper

  DIR = File.join(Rails.root, 'tmp', 'wiki_latex')

  def self.rm_rf(path)
    FileUtils.rm_r(path, force: true, secure: true)
  end

  def render_image_tag(image_name, preamble, source)
    render_to_string :template => 'wiki_latex/macro_inline', :layout => false, :locals => {:name => image_name, :source => source, :preamble => preamble}
  end

  def render_image_block(image_name, preamble, source, wiki_name)
    render_to_string :template => 'wiki_latex/macro_block', :layout => false, :locals => {:name => image_name, :source => source, :preamble => preamble, :wiki_name => wiki_name}
  end
  class Macro
    def initialize(view, full_source)
      @view = view
      @view.controller.extend(WikiLatexHelper)

      # Get rid of nasty Windows line endings.
      full_source.gsub!(/\r\n?/, "\n")

      # ???
      full_source.gsub!(/<br \/>/,"")
      full_source.gsub!(/<\/?p>/,"")
      full_source.gsub!(/<\/?div>/,"")

      # ??????
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
      if !WikiLatex.find_by_image_id(name)
        @latex = WikiLatex.new(:source => source, :image_id => name, :preamble => preamble)
        @latex.save
      end
      @latex = WikiLatex.find_by_image_id(name)
    end

    def render()
      if @latex
        @view.controller.render_image_tag(@latex.image_id, @latex.preamble, @latex.source).html_safe
      else
        @view.controller.render_image_tag("error", "error")
      end
    end
    def render_block(wiki_name)
      if @latex
        @view.controller.render_image_block(@latex.image_id, @latex.preamble, @latex.source, wiki_name).html_safe
      else
        @view.controller.render_image_block("error", "error", wiki_name)
      end
    end
  end
end
