FactoryBot.define do

  factory :legal_signatory do |f|
    # association :funding_application

      f.name {"John"}
      f.role {"John's role"}
      f.email_address {"John@test.com"}
  end

end
