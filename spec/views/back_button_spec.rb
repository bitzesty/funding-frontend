require 'rails_helper'

RSpec.describe "layouts/application", type: :view do
  include Devise::Test::ControllerHelpers

  controller_names = [
    'check_answers',
    'dashboard',
    'submitted',
    'application_submitted',
    'sessions',
    'registrations',
    'other_controller'
  ]

  controller_names.each do |controller_name|
    it "renders back button when controller_name is #{controller_name}" do
      # Stub the controller_name method
      allow(view).to receive(:controller_name).and_return(controller_name)
      
      # Stub the replace_locale_in_url method to avoid URI::InvalidURIError
      allow(view).to receive(:replace_locale_in_url).and_return('http://test.host/dummy')
  
      render
      
      if ['check_answers', 'dashboard', 'submitted', \
          'application_submitted', 'sessions', 'registrations'].exclude?(controller_name)
        expect(rendered).to have_css('div.no-print')
      else
        expect(rendered).not_to have_css('div.no-print')
      end
    end
  end
end
