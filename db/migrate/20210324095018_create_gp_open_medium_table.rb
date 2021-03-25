class CreateGpOpenMediumTable < ActiveRecord::Migration[6.1]
  def change
    create_table :gp_open_medium, id: :uuid do |t|

      # Columns copied from existing projects table
      t.string :project_title
      t.date :start_date
      t.date :end_date
      t.text :description
      t.string :line1
      t.string :line2
      t.string :line3
      t.string :townCity
      t.string :county
      t.string :postcode
      t.text :difference
      t.text :matter
      t.text :heritage_description
      t.text :best_placed_description
      t.text :involvement_description
      t.integer :permission_type
      t.text :permission_description
      t.boolean :capital_work
      t.text :declaration_reasons_description
      t.boolean :user_research_declaration, default: false
      t.boolean :keep_informed_declaration, default: false
      t.boolean :outcome_2
      t.boolean :outcome_3
      t.boolean :outcome_4
      t.boolean :outcome_5
      t.boolean :outcome_6
      t.boolean :outcome_7
      t.boolean :outcome_8
      t.boolean :outcome_9
      t.text :outcome_2_description
      t.text :outcome_3_description
      t.text :outcome_4_description
      t.text :outcome_5_description
      t.text :outcome_6_description
      t.text :outcome_7_description
      t.text :outcome_8_description
      t.text :outcome_9_description
      t.boolean :is_partnership, default: false
      t.text :partnership_details

      # Columns new to medium grants
      t.text :acquisitions_description
      t.boolean :heritage_at_risk
      t.text :heritage_at_risk_description
      t.text :heritage_formal_designation_description
      t.boolean :heritage_attracts_visitors
      t.integer :visitors_in_last_financial_year
      t.integer :visitors_expected_per_year
      t.text :potential_problems_description
      t.text :management_description
      t.text :evaluation_description
      t.text :jobs_or_apprenticeships_description
      t.text :acknowledgement_description
      t.text :received_advice_description
      t.boolean :first_fund_application
      t.string :recent_project_reference
      t.string :recent_project_title
      t.text :why_now_description
      t.text :environmental_impacts_description

      t.references :funding_application, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :int, null: false, foreign_key: true

      t.timestamps
    end
  end
end
