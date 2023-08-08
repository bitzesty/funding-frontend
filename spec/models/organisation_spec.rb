require 'rails_helper'

RSpec.describe Organisation, type: :model do
  let(:valid_organisation_1) { Organisation.new(name: 'A' * 255) }
  let(:valid_organisation_2) { Organisation.new(name: 'A' * 100) }
  let(:invalid_organisation) { Organisation.new(name: 'A' * 256) }

  it 'validates length of name to be less than or equal to 255 characters' do
    expect(invalid_organisation.valid?).to be(false)
    expect(invalid_organisation.errors[:name]).to include("Organisation name must be 255 characters or fewer")
  end

  it 'is valid when organisation name is equal to or below 255 characters' do
    expect(valid_organisation_1.valid?).to be(true)
    expect(valid_organisation_2.valid?).to be(true)
  end
end