FactoryBot.define do

  factory :statutory_permission_or_licence do |f|

    f.details_json {
      { 
        date: "2022-01-01",
        licence_type: "first permission",
        upload_question: "No, I do not have evidence yet"
      }
    }
    
  end

end
  