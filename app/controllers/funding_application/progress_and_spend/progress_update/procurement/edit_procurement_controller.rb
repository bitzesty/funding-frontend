class FundingApplication::ProgressAndSpend::ProgressUpdate::Procurement::EditProcurementController < ApplicationController
  include FundingApplicationContext
  include ProgressAndSpendHelper

  def show()
    get_procurement
  end

  def update()

    get_procurement

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

  def get_procurement()
    begin

      @procurement = progress_update.progress_update_procurement.find(params[:procurement_id])
      procurement_date = DateTime.parse(@procurement.date.to_s) 

      @procurement.date_day = procurement_date.day
      @procurement.date_month = procurement_date.month
      @procurement.date_year = procurement_date.year
    rescue ActiveRecord::RecordNotFound  
      redirect_to(
        funding_application_progress_and_spend_progress_update_procurement_procurements_summary_path(
            progress_update_id:
              @funding_application.arrears_journey_tracker.progress_update.id
        )
      )
      return
    end
  end

  def progress_update
    @funding_application.arrears_journey_tracker.progress_update
  end

  def get_params
    params.require(:progress_update_procurement).permit(
        :id,
        :name,
        :description,
        :date,
        :amount,
        :lowest_tender,
        :supplier_justification
    )
  end
end
