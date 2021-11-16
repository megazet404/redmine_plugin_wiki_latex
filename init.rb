require 'redmine'

module WikiLatexConfig

  # The path to TeX tools like 'pdflatex' and 'dvipng'. E.g. '/usr/bin/'.
  # If it is empty, the tools are searched in the PATH environment variable.
  TEX_TOOLS_PATH       = ""

  # PNG options.
  module Png

    # If this option is enabled, TikZ graphics works in PNG, but the 'convert'
    # tool is required which is not available on some platforms.
    # If the option is disabled, the 'convert' tool is not required, but TikZ
    # graphics doesn't work.
    CONVERT_VIA_PDF = false

  end

end

Rails.logger.info 'Starting wiki_latex for Redmine'

Redmine::Plugin.register :wiki_latex do
  name 'Latex Wiki-macro Plugin'
  author 'Nils Israel & Christopher Wilson'
  description 'Render latex images'
  version '0.1.0'

	Redmine::WikiFormatting::Macros.register do

		desc <<'EOF'
Latex Plugin
{{latex(place inline latex code here)}}

Don't use curly braces. '
EOF
		macro :latex, {:parse_args => false} do |wiki_content_obj, args, text|
			args = text if text
			m = WikiLatexHelper::Macro.new(self, args.to_s)
			m.render
		end


    # code borrowed from wiki template macro
    desc <<'EOF'
Include wiki page rendered with latex.
{{latex_include(WikiName)}}
EOF
    macro :latex_include do |obj, args|
      page = Wiki.find_page(args.to_s, :project => @project)
      raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)

      @included_wiki_pages ||= []
      raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
      @included_wiki_pages << page.title
      m = WikiLatexHelper::Macro.new(self, page.content.text)
      @included_wiki_pages.pop
      m.render_block(args.to_s)
    end
  end

end
