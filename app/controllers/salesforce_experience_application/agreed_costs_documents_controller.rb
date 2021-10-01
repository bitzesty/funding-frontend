class SalesforceExperienceApplication::AgreedCostsDocumentsController < ApplicationController

    # File uploader model needs following fields to pass into radio button render
    #  - errors
    #  - filename blob array 
    # - form object


    def show
        @file_upload = {files: [], errors: nil}
    end
end
