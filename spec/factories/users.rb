FactoryBot.define do

  factory :user do |f|
    users_organisations { [FactoryBot.build(:users_organisation)] }

    association :person,
                factory: :person,
                strategy: :create

    f.confirmed_at { "2020-02-05 12:20:14.391143" }
    sequence(:email){|n| "user#{n}@example.com" }
    f.password { "password" }

    f.name { "Joe Bloggs" }
    f.date_of_birth { Date.parse("01-01-1980") }
    f.phone_number { "07123456789" }
    f.line1 { "10 Downing Street" }
    f.line2 { "Westminster" }
    f.townCity { "London" }
    f.county { "LONDON" }
    f.postcode { "SW1A 2AA" }

  end

end
