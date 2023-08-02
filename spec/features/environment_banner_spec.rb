require 'rails_helper'

RSpec.feature 'test environment banner', type: :feature do
  scenario 'environment specific banner shown' do
    visit('/')
    expect(page.status_code).to eq(200)
    expect(page).to have_content('You are in environment: TEST')
  end

  scenario 'training environment banner shown' do
    ENV["RAILS_ENV"] = "training"
   
    visit('/')
    expect(page.status_code).to eq(200)
    expect(page).to have_content('You are in environment: TRAINING')
  end

  scenario 'production environment banner not shown' do
    ENV["RAILS_ENV"] = "production"
   
    visit('/')
    expect(page.status_code).to eq(200)
    expect(page).to have_no_content('You are in environment: PRODUCTION')
  end

end
