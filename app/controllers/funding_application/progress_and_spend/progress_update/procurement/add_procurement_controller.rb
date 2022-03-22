class FundingApplication::ProgressAndSpend::ProgressUpdate::Procurement::AddProcurementController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    @procurement = progress_update.progress_update_procurement.build
  end

  def update
   
    @procurement = progress_update.progress_update_procurement.build

    validate_and_update_procurement(@procurement)

    if @procurement.valid?
    redirect_to(
      funding_application_progress_and_spend_progress_update_procurement_procurements_summary_path(
        progress_update_id:  \
          @funding_application.arrears_journey_tracker.progress_update.id
        ) 
      )
    else
      render :show
    end
  
  end

  private

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  def get_params
    params.require(:progress_update_procurement).permit(
        :name,
        :description,
        :date,
        :amount,
        :lowest_tender,
        :supplier_justification
    )
  end
end
