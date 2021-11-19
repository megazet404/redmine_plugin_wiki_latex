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
    def initialize(view, source)
      @view = view
      @view.controller.extend(WikiLatexHelper)
      preamble = ''
      if source.include? '|||||'
        ary = source.split('|||||')
        source = ary[1]
        preamble = ary[0]
      end
      source.gsub!(/<br \/>/,"")
      source.gsub!(/<\/?p>/,"")
      source.gsub!(/<\/?div>/,"")
      preamble.gsub!(/<br \/>/,"")
      preamble.gsub!(/<\/?p>/,"")
      preamble.gsub!(/<\/?div>/,"")
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
