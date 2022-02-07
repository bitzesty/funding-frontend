class AddRoleToLegalSignatories < ActiveRecord::Migration[6.1]
  def change
    add_column :legal_signatories, :role, :string
    add_column :legal_signatories, :salesforce_legal_signatory_id, :string
  end
end
