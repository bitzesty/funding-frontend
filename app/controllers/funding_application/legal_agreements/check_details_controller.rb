class FundingApplication::LegalAgreements::CheckDetailsController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include CheckDetailsHelper

  # These constants are rendered in the view and used by this controller's
  # store_page_content method to section and store relevant page info.
  # Helps prevent view alterations breaking store_page_content method
  SECTION_START_HTML = '<section id="agreements_project_details_html">'
  SECTION_END_HTML = '<section id="button">'

  def show

    set_award_type(@funding_application)
    
    content = salesforce_content_for_form(@funding_application)

    # @project_details is a Restforce object containing query results 
    @project_details = content[:project_details]

    # @project_costs is a Restforce object containing costs
    @project_costs = content[:project_costs]

    # @cash_contributions is a Restforce object containing costs
    @cash_contributions = content[:cash_contributions]

    # @project_approved_purposes is a Restforce object containing costs
    @project_approved_purposes = content[:project_approved_purposes]

    # upon show, only cerain content is shown for 10-250k applications.
    @award_more_than_10k = @funding_application.open_medium.present?

    # get the relevant links for the award type
    @standard_terms_link = get_standard_terms_link(@funding_application)

    @retrieving_a_grant_guidance_link =
      get_receiving_a_grant_guidance_link(@funding_application)

    @section_start_html = SECTION_START_HTML
    @section_end_html = SECTION_END_HTML

    store_page_content(render_to_string(:show))

  end

  helper_method :get_translation

  private
    
    # Method to store some page content for the project_details_html column
    # on the agreements table. Used to display to an applicant later 
    # if they check what details they agreed to.
    # Uses string manipulation to remove unwanted text and buttons.
    #
    # @param [page_content] String Contains all HTML for the page
    #         
    def store_page_content(page_content)
      
      @funding_application.agreement.project_details_html = page_content

      # find the index for the start of the content we want
      index_for_start_of_of_relevant_info = 
        @funding_application.agreement.project_details_html.index(
          SECTION_START_HTML
        )
        
      # Re-assign the content we want to the model.        
      @funding_application.agreement.project_details_html = 
        @funding_application.agreement.project_details_html[
          index_for_start_of_of_relevant_info..-1  
        ] unless index_for_start_of_of_relevant_info.nil?
      
      # Find the section that shows the unrequired button HTML at the page end
      index_for_button_html = 
        @funding_application.agreement.project_details_html.index(
          SECTION_END_HTML
        )
  
      # Remove all HTML from the button onwards
      @funding_application.agreement.project_details_html[
        index_for_button_html..-1
      ] = "" unless index_for_button_html.nil?
  
      @funding_application.agreement.save

    end

end
