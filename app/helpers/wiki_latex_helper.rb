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

    def render()
      @view.controller.render_image_tag(@latex.image_id, @latex.preamble, @latex.source).html_safe
    end
    def render_block(wiki_name)
      @view.controller.render_image_block(@latex.image_id, @latex.preamble, @latex.source, wiki_name).html_safe
    end
  end
end
