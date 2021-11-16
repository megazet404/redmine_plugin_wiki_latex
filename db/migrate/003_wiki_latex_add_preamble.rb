class WikiLatexAddPreamble < ActiveRecord::Migration[4.2]

  def self.up
    add_column :wiki_latexes, :preamble, :text, after: :source, :null => false, :default => ""
  end

  def self.down
    remove_column :wiki_latexes, :preamble
  end
end
