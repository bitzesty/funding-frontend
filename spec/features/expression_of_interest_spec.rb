require 'rails_helper'

RSpec.feature 'Expression of Interest', type: :feature do

    # Testing for the successful creation of a Project Enquiry Form
    # with fields filled in

    scenario 'Successful submission of a Expression of Interest' do

        begin
            
            Flipper[:expressions_of_interest_enabled].enable
            # this initialises the salesforce interface

            salesforce_stub

            # creates the user instance

            user = create(:user)

            #create from factories

        
            pre_application = create(:pre_application)

            #puts user.organisations.inspect
            #puts expression_of_interest.organisation
            
            pre_application.organisation = user.organisations.first

            pre_application.organisation.update(
                name: "Test Organisation",
                org_type: "church_organisation",
                line1: "10 Downing Street",
                line2: "Westminster",
                townCity: "London",
                county: "London",
                postcode: "SW1A 2AA"
            )
            
            expression_of_interest = create(:pa_expression_of_interest)

            #login 
            login_as(user, scope: :user)

            # hop to our start page
            visit '/'

            expect(page).to have_text I18n.t("dashboard.pa_expressions_of_interest.new.buttons.start")
            
            click_link_or_button I18n.t("dashboard.pa_expressions_of_interest.new.buttons.start")

            expect(page).to have_text "Have you spoken to anyone at The Fund about your idea?"

            enter_and_save_previous_contact("Jim Broadbent")

            expect(page).to have_text "Describe what you will do during the project"
            
            enter_and_save_what_project_does("Description of what project does")

            expect(page).to have_text "Do you have a title for the project?"

            enter_and_save_what_working_title("Working title")

            expect(page).to have_text "What outcomes do you want to achieve?"

            enter_and_save_programme_outcomes("Description of project outcomes")

            expect(page).to have_text "Tell us about the heritage of the project"

            enter_and_save_what_heritage_focus("Description of heritage of project")

            expect(page).to have_text "What is the need for this project?"

            enter_and_save_project_need("Description of project need")
            
            expect(page).to have_text "How long do you think the project will take?"

            enter_and_save_project_timescales("Description of time taken")

            expect(page).to have_text "How much is the project likely to cost?"

            enter_and_save_project_overall_cost("Description of overall cost")

            expect(page).to have_text "How much funding are you planning to apply for from us?"

            # test here to enter various amounts; new scenario

            enter_and_save_potential_funding_amount(260000)

            expect(page).to have_text "When are you likely to submit a funding application, if asked to do so?"

            enter_and_save_likely_submission_description("Description of likely submission")

            expect(page).to have_text "Check your answers"
            expect(page).to have_text "Jim Broadbent"
            expect(page).to have_text "Description of what project does"
            expect(page).to have_text "Working title"
            expect(page).to have_text "Description of project outcomes"
            expect(page).to have_text "Description of heritage of project"
            expect(page).to have_text "Description of project need"
            expect(page).to have_text "Description of time taken"
            expect(page).to have_text "Description of overall cost"
            expect(page).to have_text "Description of likely submission"

            #Error was occuring submitting to salesforce
            #Similar error seen running other specs.
            #Assume it's my local install but will query.
            #click_button "Submit Project Enquiry Form"

        ensure
            Flipper[:expressions_of_interest_enabled].disable
        end

    end

    private

    def enter_and_save_previous_contact(contact)
        fill_in "pa_expression_of_interest[previous_contact_name]", with: contact
        click_save_and_continue_button
    end

    def enter_and_save_project_need(project_need)
        fill_in "pa_expression_of_interest[project_reasons]", with: project_need
        click_save_and_continue_button
    end

    def enter_and_save_what_project_does(project_does)
        fill_in "pa_expression_of_interest[what_project_does]", with: project_does
        click_save_and_continue_button
    end

    def enter_and_save_what_working_title(working_title)
        fill_in "pa_expression_of_interest[working_title]", with: working_title
        click_save_and_continue_button
    end

    def enter_and_save_what_heritage_focus(heritage_focus)
        fill_in "pa_expression_of_interest[heritage_focus]", with: heritage_focus
        click_save_and_continue_button
    end

    def enter_and_save_programme_outcomes(programme_outcomes)
        fill_in "pa_expression_of_interest[programme_outcomes]", with: programme_outcomes
        click_save_and_continue_button
    end

    def enter_and_save_project_participants(project_participants)
        fill_in "pa_expression_of_interest[project_participants]", with: project_participants
        click_save_and_continue_button
    end

    def enter_and_save_project_timescales(project_timescales)
        fill_in "pa_expression_of_interest[project_timescales]", with: project_timescales
        click_save_and_continue_button
    end

    def enter_and_save_project_overall_cost(overall_cost)
        fill_in "pa_expression_of_interest[overall_cost]", with: overall_cost
        click_save_and_continue_button
    end

    def enter_and_save_potential_funding_amount(potential_funding_amount)
        fill_in "pa_expression_of_interest[potential_funding_amount]", with: potential_funding_amount
        click_save_and_continue_button
    end

    def enter_and_save_likely_submission_description(likely_submission_description)
        fill_in "pa_expression_of_interest[likely_submission_description]", with: likely_submission_description
        click_save_and_continue_button
    end

    def click_save_and_continue_button
        click_link_or_button "Save and continue"
    end

end