class OpenMediumHeritageDesignation < ApplicationRecord

  # This overrides Rails attempting to pluralise the model name
  self.table_name = 'gp_o_m_heritage_dsgntns'

  belongs_to :open_medium, foreign_key: 'gp_open_medium_id'
  belongs_to :heritage_designation

end
