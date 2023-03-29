# Controller used to return health check status for GOV.UK PaaS
class HealthController < ApplicationController
  skip_before_action :check_ffe_enabled!

  # Returns application status and the current server timestamp
  #
  # @return [JSON] a JSON object containing the application status
  #                and the current server timestamp
  def status

    render(
      json: {
        status: 'OK',
        server_timestamp: Time.new.strftime('%Y-%m-%d %H:%M:%S')
      },
      status: 200
    )

  end

end
