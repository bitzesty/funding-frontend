require 'rails_helper'

RSpec.feature 'Application', type: :feature do
  scenario 'Signed out user' do
    visit('/')
    expect(page.status_code).to eq(200)
    expect(page).to have_content('Sign in')
    expect(page).to have_content('Problems signing in?')
  end

  scenario 'About you page' do

    user = FactoryBot.create(
        :user,
        name: nil,
        date_of_birth: nil,
        phone_number: nil
    )
    login_as(user, scope: :user)
    visit('/')
    expect(page).to have_content('About you')
    fill_in 'Full name', with: 'Jane Doe'
    fill_in 'Telephone number', with: '123'
    fill_in 'Day', with: '01'
    fill_in 'Month', with: '01'
    fill_in 'Year', with: '1970'
    click_button 'Save and continue'

    # import todo: This test currently fail because I'm throwing up a POC
    # page with a SF call in the show.  Fix when proper page in place.

    expect(page)
        .to have_current_path("/user/#{user.organisations.first.id}/address/postcode?locale=en-GB")
  end

end