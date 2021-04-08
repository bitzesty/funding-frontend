class AddOwnershipTypeToGpOpenMedium < ActiveRecord::Migration[6.1]
  def change
    add_column :gp_open_medium, :ownership_type, :string
    add_column :gp_open_medium, :ownership_type_org_description, :text
    add_column :gp_open_medium, :ownership_type_pp_description, :text
    add_column :gp_open_medium, :ownership_type_neither_description, :text
  end
end
