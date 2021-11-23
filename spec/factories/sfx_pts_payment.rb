FactoryBot.define do

  factory :sfx_pts_payment do |f|

    statutory_permission_or_licence  { 
      [FactoryBot.build(:statutory_permission_or_licence)]
    }

    f.salesforce_case_id { "5003G000006Ne8aQAC" }
    f.application_type { 0 } # delivery phase app by default
    f.pts_answers_json {
      { 
        legal_sig_one: "signatory_one",
        legal_sig_two: "signatory_two",
        agreed_costs_match: "true",
        project_partner_name: "project_partner_name",
        agrees_to_declaration: "true",
        has_agreed_costs_docs: "false",
        approved_purposes_match: "true",
        partnership_application: "true",
        cash_contributions_correct: "true",
        fundraising_evidence_question: I18n.t("salesforce_experience_" \
          "application.fundraising_evidence.bullets.i_have_emailed"),
        non_cash_contributions_correct: "true",
        permissions_or_licences_received: "false", 
        timetable_work_programme_question: I18n.t("salesforce_experience_" \
          "application.timetable_work_programme.bullets.i_have_emailed"),
        cash_contributions_evidence_question: I18n.t("salesforce_experience_" \
          "application.cash_contribution_evidence.bullets." \
            "i_provided_evidence"),
        property_ownership_evidence_question: I18n.t("salesforce_experience_" \
          "application.property_ownership_evidence.bullets.i_have_emailed"),
        project_management_structure_question: I18n.t("salesforce_experience_"\
          "application.project_management_structure.bullets.i_have_emailed"),
      }
    }

  end

end
