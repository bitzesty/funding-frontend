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

    @applicant_is_legal_signatory = is_applicant_legal_signatory?(
      @funding_application,
      current_user
    )

    set_award_type(@funding_application)

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

    # This was duplicated from sign terms controller during a bug fix.  
    # Given time, would be good to write a helper function to consolidate the
    # filenames in one place.  Maybe cater for the signatory download links 
    # too.
    @download_link = 
      '/terms_and_conditions/Applicant only National Lottery Heritage Fund terms and ' \
        'conditions for £3,000 to £10,000.docx' \
          if @funding_application.is_3_to_10k?

    @download_link = 
      '/terms_and_conditions/Applicant only National Lottery Heritage ' \
        'Fund terms and conditions for £10,000 to £100,000.docx' \
          if @funding_application.is_10_to_100k?

    @download_link = 
      '/terms_and_conditions/Applicant only National Lottery Heritage ' \
        'Fund terms and conditions for £100,000 to £250,000.docx' \
          if @funding_application.is_100_to_250k?
    
    store_page_content(render_to_string(:show))
    
  end

  def update

    logger.info(
      'Updating terms_agreed_at attribute for funding_application ID: ' \
      "#{@funding_application.id}"
    )

    @funding_application.agreement.update(
      terms_agreed_at: DateTime.now
    )

    logger.info(
      'Finished Updating terms_agreed_at attribute for ' \
      "funding_application ID: #{@funding_application.id}"
    )

    redirect_to(:funding_application_agreed)

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

      @funding_application.agreement.save

    end

end
