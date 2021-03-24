class UpdateOrganisationsDataModel < ActiveRecord::Migration[6.1]
  def change
    add_column :organisations, :main_purpose_and_activities, :text
    add_column :organisations, :spend_in_last_financial_year, :decimal
    add_column :organisations, :unrestricted_funds, :decimal
    add_column :organisations, :board_members_or_trustees, :integer
    add_column :organisations, :vat_registered, :boolean
    add_column :organisations, :vat_number, :string
    add_column :organisations, :social_media_info, :text
  end
end
