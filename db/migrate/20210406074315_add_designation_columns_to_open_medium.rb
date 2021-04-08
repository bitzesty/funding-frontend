class AddDesignationColumnsToOpenMedium < ActiveRecord::Migration[6.1]
  def change
    add_column :gp_open_medium, :hd_grade_1_description, :text
    add_column :gp_open_medium, :hd_grade_2_b_description, :text
    add_column :gp_open_medium, :hd_grade_2_c_description, :text
    add_column :gp_open_medium, :hd_local_list_description, :text
    add_column :gp_open_medium, :hd_monument_description, :text
    add_column :gp_open_medium, :hd_historic_ship_description, :text
    add_column :gp_open_medium, :hd_grade_1_park_description, :text
    add_column :gp_open_medium, :hd_grade_2_park_description, :text
    add_column :gp_open_medium, :hd_grade_2_star_park_description, :text
    add_column :gp_open_medium, :hd_other_description, :text
  end
end
