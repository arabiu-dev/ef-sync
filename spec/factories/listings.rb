FactoryBot.define do
  factory :listing do
    sequence(:listing_number) { |n| 70_000 + n }
    listing_price   { 150_000 }
    listing_status  { "For Sale" }
    summary         { "A great online business for sale" }
    hubspot_deal_id { nil }
  end
end