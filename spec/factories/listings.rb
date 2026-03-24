FactoryBot.define do
  factory :listing do
    listing_number { 1 }
    listing_price { "9.99" }
    summary { "MyText" }
    listing_status { "MyString" }
    hubspot_deal_id { 1 }
  end
end
