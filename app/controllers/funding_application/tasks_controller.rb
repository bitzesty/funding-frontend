class FundingApplication::TasksController < ApplicationController
  include FundingApplicationContext, ObjectErrorsLogger

  def show

    @first_payment_not_started = @funding_application&.payment_requests&.first.nil?

    @first_payment_in_progress = @funding_application&.payment_requests&.first.present? && \
      @funding_application&.payment_requests&.first&.submitted_on.nil?

    @first_payment_completed = @funding_application&.payment_requests&.first&.submitted_on.present? 
  
  end

end
