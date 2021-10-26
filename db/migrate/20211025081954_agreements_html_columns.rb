class AgreementsHtmlColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :agreements, :project_details_html, :text
    add_column :agreements, :terms_html, :text
  end
end
