class FixDesignationDataTypes < ActiveRecord::Migration[6.1]
  def change
    change_column :gp_open_medium, :hd_grade_1_description, :integer, using: 'hd_grade_1_description::integer'
    change_column :gp_open_medium, :hd_grade_2_b_description, :integer, using: 'hd_grade_2_b_description::integer'
    change_column :gp_open_medium, :hd_grade_2_c_description, :integer, using: 'hd_grade_2_c_description::integer'
    change_column :gp_open_medium, :hd_local_list_description, :integer, using: 'hd_local_list_description::integer'
    change_column :gp_open_medium, :hd_monument_description, :integer, using: 'hd_monument_description::integer'
  end
end
