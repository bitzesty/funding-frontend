class FundingApplication::LegalAgreements::TermsController < ApplicationController
  include FundingApplicationContext
  include FundingApplicationHelper
  include ObjectErrorsLogger
  include LegalAgreementsHelper

  # These constants are rendered in the view and used by this controller's
  # store_page_content method to section and store relevant page info.
  # Helps prevent view alterations breaking store_page_content method
  SECTION_START_HTML = '<section id="agreements_terms_html">'
  SECTION_END_HTML = '<section id="applicant_specific_info">'

  def show

    @award_more_than_10k = @funding_application.open_medium.present?

    @standard_terms_link = get_standard_terms_link(@funding_application)

    @retrieving_a_grant_guidance_link =
      get_receiving_a_grant_guidance_link(@funding_application)

    @receiving_guidance_property_ownership_link =  
      get_receiving_guidance_property_ownership_link(@funding_application)

    @programme_application_guidance =
      get_programme_application_guidance_link(@funding_application)
    
    @additional_grant_conditions = additional_grant_conditions(@funding_application)

    @investment_manager_name = project_details(@funding_application).Owner.Name

    @section_start_html = SECTION_START_HTML
    @section_end_html = SECTION_END_HTML

    store_page_content(render_to_string(:show))
    
  end

  def update

    # button on view links to agreed

  end

  private
    
    # Method to store some page content for the terms_html column
    # on the agreements table. Used to display to an applicant later 
    # if they check what terms they agreed to.
    # Uses string manipulation to remove unwanted text and buttons.
    #
    # @param [page_content] String Contains all HTML for the page
    #         
    def store_page_content(page_content)

      @funding_application.agreement.terms_html = page_content

      # find the index for the start of the content we want
      index_for_start_of_of_relevant_info = 
        @funding_application.agreement.terms_html.index(
          SECTION_START_HTML
        )
        
      # Re-assign the content we want to the model. If the index
      # is invalid - it will store all the header information too     
      @funding_application.agreement.terms_html = 
        @funding_application.agreement.terms_html[
          index_for_start_of_of_relevant_info..-1  
        ] unless index_for_start_of_of_relevant_info.nil?
      
      # Find the section that shows the unrequired applicant specific HTML 
      index_for_applicant_html = 
        @funding_application.agreement.terms_html.index(
          SECTION_END_HTML
        )

      # Remove all HTML from the button onwards
      @funding_application.agreement.terms_html[
        index_for_applicant_html..-1
      ] = "" unless index_for_applicant_html.nil?

      # Remove check_and_confirm_text
      @funding_application.agreement.terms_html =     
        @funding_application.agreement.terms_html.gsub(
          t('agreement.terms.sub_headings.check_and_confirm'), 
          ""
        )
    
      # Remove release payment of grant text
      @funding_application.agreement.terms_html =     
        @funding_application.agreement.terms_html.gsub(
          t('agreement.to_release_payment'), 
          ""
        )

      # Remove Download terms and conditions link
      @funding_application.agreement.terms_html =     
      @funding_application.agreement.terms_html.gsub(
        t('agreement.terms.download_terms_and_conditions'), 
        ""
      )

      @funding_application.agreement.save

    end

end
