require 'redmine'

module WikiLatexConfig

  # The path to LaTeX tools like 'pdflatex' and 'dvipng'. E.g. '/usr/bin/'.
  # If it is empty, the tools are searched in the PATH environment variable.
  TOOLS_PATH           = ""

  # If this option is enable, the tmp/wiki_latex/ directory is removed at Redmine
  # startup. The directory contains LaTeX sources and cached LaTeX images. They
  # are regenerated when the pages with the LaTeX macros are requested.
  CLEAN_FILES_ON_START = false

  # If this option is enabled, then all 'latex'/'pdflatex' output messages are
  # suppressed.
  LATEX_NO_OUTPUT      = false

  # If this option is enabled, the '--quiet' option is added to 'latex'/'pdflatex'.
  # Not all TeX distributions support it. Adding '--quiet' suppress all output,
  # except errors.
  LATEX_QUIET          = false

  # PNG options.
  module Png

    # If this option is enabled, TikZ graphics works in PNG, but the 'convert'
    # tool of ImageMagick together with Ghostscript is required.
    # If the option is disabled, the 'convert' tool is not required, but TikZ
    # graphics doesn't work.
    GRAPHICS_SUPPORT = false

  end

end

################################################################

def get_macro_content(args, text)
  # Convert array to string if 'args' is array (it shouldn't be if ':parse_args => false')
  args = args.join(",") if args.kind_of?(Array)

  # Check if multiline macro.
  if !text.nil?
    raise "no parameters are supported in multiline macro" if args != ""
    return text
  end

  # Return 'args' as the content of macro.
  return args
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
      latex_source_code = get_macro_content(args, text)
      m = WikiLatexHelper::Macro.new(self, latex_source_code)
      m.render
    end


    # code borrowed from wiki template macro
    desc <<'EOF'
Include wiki page rendered with latex.
{{latex_include(WikiName)}}
EOF
    macro :latex_include, {:parse_args => false} do |obj, args, text|
      raise "latex_include can't be multiline" if !text.nil?
      page_title = get_macro_content(args, text)
      page = Wiki.find_page(page_title, :project => @project)
      raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)

      @included_wiki_pages ||= []
      raise 'Circular inclusion detected' if @included_wiki_pages.include?(page.title)
      @included_wiki_pages << page.title
      m = WikiLatexHelper::Macro.new(self, page.content.text)
      @included_wiki_pages.pop
      m.render_block(page_title)
    end
  end

end

if WikiLatexConfig::CLEAN_FILES_ON_START
  WikiLatexHelper::rm_rf(WikiLatexHelper::DIR)
else
  # Remove possible garbage.
  dir = File.join(WikiLatexHelper::DIR, "")
  ['tex','pdf','eps','log','aux','dvi'].each do |ext|
    WikiLatexHelper::rm_rf(Dir.glob("#{dir}*.#{ext}"))
  end
end
