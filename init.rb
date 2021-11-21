require 'redmine'

module WikiLatexConfig

  # The path to LaTeX tools like 'pdflatex' and 'dvipng'. E.g. '/usr/bin/'.
  # If it is empty, the tools are searched in the PATH environment variable.
  TOOLS_PATH           = ""

  # If this option is enabled, the LaTeX sources are stored in the database.
  # If it is disabled, the LaTeX sources are stored in files.
  # Note that the files and the database entries are not deleted when the
  # LaTeX formulas are no longer in use (deleted from a wiki page). So you have
  # to delete them manually periodically. It safe to delete all files in the
  # tmp/wiki_latex/ directory. If you set this option to true, you have to
  # delete the database entries as well.
  STORE_LATEX_IN_DB    = false

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

  # Use this option to make LaTeX formulas bigger or smaller.
  ZOOM_FACTOR          = 1.0

  # PNG options.
  module Png

    # If this option is enabled, TikZ graphics works in PNG, but the 'convert'
    # tool of ImageMagick together with Ghostscript is required.
    # If the option is disabled, the 'convert' tool is not required, but TikZ
    # graphics doesn't work.
    GRAPHICS_SUPPORT = false

  end

  # SVG options.
  module Svg

    # The plugin stores the LaTeX SVG files in gzip archives.
    # If this option is enabled, The plugin sends the SVG files compressed,
    # then the browser decompresses them.
    # If the option is disabled, then the plugin decompresses the files before
    # sending them to the browser.
    CLIENT_SIDE_DECOMPRESSION = true

    # If this option is enabled, then the fonts are embedded to the SVG files.
    # If it is disabled, then all text in SVG files is presented as vectorized
    # lines.
    EMBED_FONT                = true

    # The size of a transparent border around the LaTeX content. Since cropping
    # the LaTeX content in SVG images is not perfect even with '-e' option of
    # 'dvisvgm', setting this option to '0' may produce clipped SVG images.
    BORDER                    = 1

    # This option can be set to 'Z' or 'c'.
    # 'Z' - first adds the border then scales SVG (the border is scaled too).
    # 'c' - first scales SVG then adds the border (the border is not scaled).
    ZOOM_METHOD               = "Z"

    # It seems that 'dvisvgm' is not "thread" safe. If multiple instances run
    # simultaneously, they cannot create temporary files sometimes.
    # If this option is enabled, the plugin creates a separate temporary
    # directory for each instance of 'dvisvgm'. This works around the problem.
    WA_MAKE_TMP               = true

  end

  # Workarounds.
  module Wa

    # For some reasons, 'content_for' doesn't work without using the "view"
    # object in the wiki_latex ERB template. The wiki_latex CSS is not linked
    # to the page because of that. This WA makes using 'view' explicitly for
    # 'content_for'.
    CSS_VIA_VIEW = true

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
      WikiLatexHelper::Macro.render_inline(latex_source_code, self)
    end

    # code borrowed from wiki template macro
    desc <<'EOF'
Include wiki page rendered with latex.
{{latex_include(WikiName)}}
EOF
    macro :latex_include, {:parse_args => false} do |obj, args, text|
      raise "latex_include can't be multiline" if !text.nil?
      page_title = get_macro_content(args, text)
      WikiLatexHelper::Macro.render_block(@project, page_title, self)
    end
  end
end

if WikiLatexConfig::CLEAN_FILES_ON_START
  WikiLatexHelper::rm_rf(WikiLatexHelper::DIR)
else
  # Remove possible garbage.
  dir = File.join(WikiLatexHelper::DIR, "")
  ['pdf','eps','dvi','log','aux','tmp'].each do |ext|
    WikiLatexHelper::rm_rf(Dir.glob("#{dir}*.#{ext}"))
  end
end
