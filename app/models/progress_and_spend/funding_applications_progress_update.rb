class FundingApplicationsProgressUpdate < ApplicationRecord
  self.table_name = 'fndng_applctns_prgrss_updts'

  belongs_to :funding_application
  belongs_to :progress_update

end