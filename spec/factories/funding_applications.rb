FactoryBot.define do

    factory :funding_application do
      association :organisation,
                  factory: :organisation,
                  strategy: :build
      association :project,  
                  factory: :project,
                  strategy: :build
      # association :funding_applications_legal_sigs,
      #             factory: :funding_applications_legal_sig,
      #             strategy: :build
    end
  
  end
  