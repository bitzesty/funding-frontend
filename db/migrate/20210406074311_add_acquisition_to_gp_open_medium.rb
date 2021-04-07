class AddAcquisitionToGpOpenMedium < ActiveRecord::Migration[6.1]
  def change
    add_column :gp_open_medium, :acquisition, :boolean
  end
end
