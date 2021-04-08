class HeritageDesignation < ApplicationRecord
    has_many :open_medium_heritage_designations, inverse_of: :heritage_designation
    has_many :open_medium, through: :open_medium_heritage_designations, foreign_key: 'gp_open_medium_id'
  end
