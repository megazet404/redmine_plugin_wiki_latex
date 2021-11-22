# Redmine wiki latex plugin

This is _LaTeX_ plugin for _Redmine_ that allows to display rendered LaTeX formulas in Redmine's _Wiki_.

This edition of _Redmine wiki latex_ plugin works on _Linux_ and _Windows_ (it probably works on other platforms too). It also supports rendering to _SVG_. It is compatible with _Redmine 4.x_ and some older versions.

The plugin uses LaTeX tools directly, so you have to install some LaTeX distribution to make the plugin work. But its advantage is that it doesn't send your LaTeX code to 3rd party servers as some other LaTeX plugins for Redmine do.

# Installation and usage

## Prerequisites

### Linux

Requires the folowing debian packages:
* dvipng
* texlive-recomended
* preview-latex-style

### Windows

Install _MiKTeX_.

## Installation

1. Name the folder `wiki_latex`, not `wiki_latex_plugin`, and place it in the `plugins` directory of Redmine.
2. Create the database tables using `rake redmine:plugins:migrate RAILS_ENV=production`.
3. Restart Redmine.
4. The plugin should appear in the administration panel.

For more instructions visit http://www.redmine.org/projects/redmine/wiki/Plugins.

### Problems

If your version of Rails is too old then before creating database tables you have to edit files in [_db/migrate/_](db/migrate/) directory. Change `ActiveRecord::Migration[4.2]` to `ActiveRecord::Migration`.

## Configuration

Configuration options are available in the [_init.rb_](init.rb) file.
You can customize LaTeX options in the [_assets/latex/_](assets/latex/) directory.
You can customize CSS in the [_assets/stylesheets/wiki_latex.css_](assets/stylesheets/wiki_latex.css) file.
You can switch back to PNG by editing [_macro_inline.html.erb_](app/views/wiki_latex/macro_inline.html.erb) and [_macro_block.html.erb_](app/views/wiki_latex/macro_block.html.erb) templates in the [_app/views/wiki_latex/_](app/views/wiki_latex/) directory (change `image_svg` to `image_png`).

## Usage

1. LaTeX can be inserted into a Wiki via Redmine's wiki macro:
    ```tex
    {{latex( $a=x_2$ )}}
    ```
2. Preambles can be specified if necessary with:
    ```tex
    {{latex( \usepackage{tikz}|||||\begin{tikzpicture}\draw [red] (0,0) rectangle (1,1);\end{tikzpicture} )}}
    ```
3. Multiline syntax can be used:
    ```tex
    {{latex
      \usepackage{tikz}
    |||||
      \begin{tikzpicture}
        \draw [red] (0,0) rectangle (1,1);
      \end{tikzpicture}
    }}
    ```

# Update history

* Updated by _megazet404_ (https://github.com/megazet404):
  * Made it work with Redmine 4.x.
  * Made it work on Windows.
  * Added SVG support.
  * Added support to work without database.
* Updated by _Christopher Wilson_ (https://github.com/wilsoc5):
  * Made it work with Redmine 3.x.
  * Added preamble support.
* Updated by _Paul Morelle_ (https://github.com/madprog):
  * Added support for graphics with tikz & pgfplots.
  * Added support for new lines in latex macro.
* Updated by _Herman Fries_ (https://github.com/baracoder):
  * Made it work with Redmine 2.x.
* Original Code by _Nils Israel_ (https://github.com/nisrael):
* Based on _wiki_graphviz_plugin_ by _tckz_ (<at.tckz@gmail.com>).

# License

_GPL version 2 or later_

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
