Redmine Wiki Latex-macro plugin will allow Redmines wiki to render
image from latex code.
 
UPDATED by Christopher Wilson to work in Redmine 3.0.x.
Based on code: 
Updated by Paul Morelle (https://github.com/madprog)
Updated by Herman Fries (https://github.com/baracoder)
Original Code: 
Copyright (C) 2009 Nils Israel <info@nils-israel.net>
Based on wiki_graphviz_plugin by tckz<at.tckz@gmail.com>

Requieres folowing debian packages

	* dvipng
	* texlive-recomended
	* preview-latex-style

Modified version to work with redmine 3.x


INSTALLATION

1. Name the folder `wiki_latex` not `wiki_latex_plugin` and place it in the /plugins directory
2. Create the database tables using `rake redmine:plugins:migrate RAILS_ENV=production`
3. Restart redmine
4. The plugin should appear in the administartion panel

For more insturctions: http://www.redmine.org/projects/redmine/wiki/Plugins

USAGE:
1. Latex can be inserted into a Wiki via:

{{latex($a=x_2$}}

2. Preambles can be specified if necessary with:

{{latex(\usepackage{tikz}|||||\begin{tikzpicture}\draw [red] (0,0) rectangle (1,1);\end{tikzpicture})}}

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
