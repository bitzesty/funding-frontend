require "rails_helper"

RSpec.describe FundingApplication::LegalAgreements::CheckDetailsController do

  describe "#get_translation" do

    it "should have access to english translations that are paramterised, underscored versions of itself" do

      # Simple test of the translations to check that each translation index is a key 
      # that is a parameterised, underscored version of the text it points at.
      # Technially this is testing that the translations the function needs are right,
      # not the function itself.

      I18n.t('salesforce_text.project_costs').each do |translation|
        expect(translation[0].to_s).to eq(translation[1].parameterize.underscore)
      end

    end

    it "should return New staff for key 'new_staff' when local is en-GB " do

      I18n.locale = 'en-GB'
      
      expect(subject.get_translation("New staff")).to eq("New staff")
      
    end

    it "should return New staff for key 'new_staff' when local is cy " do

      I18n.locale = 'cy'

      begin
        expect(subject.get_translation("New staff")).to eq("Staff newydd")
      ensure
        I18n.locale = 'en-GB'
      end
      
    end

    it "should raise an exception for an unknown key" do
      
      expect{subject.get_translation("unknown key")}.to \
        raise_error(
          StandardError, 
          'translation missing for cost heading unknown key'
        )
          
    end


  end

end
