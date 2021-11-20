match 'latex/:image_id.png', to: 'wiki_latex#image_png', via: [:get,:post]
match 'latex/:image_id.svg', to: 'wiki_latex#image_svg', via: [:get,:post]
