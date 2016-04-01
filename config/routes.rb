match 'latex/:image_id.png', to: 'wiki_latex#image', via: [:get,:post]
match 'latex/:image_id.svg', to: 'wiki_latex#imagesvg', via: [:get,:post]
match 'latex/:image_id.svgz', to: 'wiki_latex#imagesvgz', via: [:get,:post]
match 'latex/:image_id.pdf', to: 'wiki_latex#pdf', via: [:get,:post]
