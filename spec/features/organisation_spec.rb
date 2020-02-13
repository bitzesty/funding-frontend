require 'rails_helper'
RSpec.feature 'Organisation', type: :feature do
  scenario 'Organisation creation' do
  user = FactoryBot.create(:user, name: 'Jane Doe', date_of_birth: Date.new,  line1: 'line 1', phone_number: '123', postcode: 'W11AA', townCity: 'London', county: 'London')
  login_as(user, :scope => :user)
  visit '/'
  expect(page).to have_text 'Start a new project'
  click_link_or_button 'Start a new project'
  click_link_or_button 'Start Now'
  choose 'Registered charity'
  click_link_or_button 'Save and continue'
  fill_in 'organisation[charity_number]', with: '123'
  click_link_or_button 'Save and continue'
  set_address(title_field = 'Organisation name')
  check 'Female led'
  click_link_or_button 'Save and continue'
  fill_in 'Full name', match: :first, with: 'Jane Doe'
  fill_in 'Email address', match: :first, with: 'test@example.com'
  fill_in 'Phone number', match: :first, with: '123'
  click_link_or_button 'Save and continue'
  expect(page).to have_text('Check your answers')
  expect(page).to have_text('Registered charity')
  expect(page).to have_text('123')
  expect(page).to have_text('test')
  expect(page).to have_text('4 Barons Court Road')
  expect(page).to have_text('London')
  expect(page).to have_text('W14 9DT')
  expect(page).to have_text('Female led')
  expect(page).to have_text('Jane Doe')
  organisation = User.find(user.id).organisation
  expect(organisation.org_type).to eq('registered_charity')
  expect(organisation.charity_number).to eq('123')
  expect(organisation.name).to eq('test')
  expect(organisation.line1).to eq('4 Barons Court Road')
  expect(organisation.townCity).to eq('LONDON')
  expect(organisation.county).to eq('London')
  expect(organisation.postcode).to eq('W14 9DT')
  expect(organisation.mission).to include('female_led')
  expect(organisation.legal_signatories.first.name).to eq('Jane Doe')
  end
end