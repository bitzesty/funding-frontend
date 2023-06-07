class AdminPortal::ReconnectionReportController < ApplicationController
    include AdminPortalContext
    include ImportHelper

    def show

        projects_for_reconnection = get_projects_selected_for_reconnection

        @report =
            populate_temporary_table_and_run_report(projects_for_reconnection)
    end
  
  end
