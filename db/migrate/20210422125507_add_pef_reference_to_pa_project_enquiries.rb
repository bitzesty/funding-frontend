class AddPefReferenceToPaProjectEnquiries < ActiveRecord::Migration[6.1]
  def change
    add_column :pa_project_enquiries, :salesforce_pef_reference, :string
  end
end
