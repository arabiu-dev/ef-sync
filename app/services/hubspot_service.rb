class HubspotService
  def initialize
    @client = Hubspot::Client.new(
      access_token: Rails.application.credentials.dig(:hubspot, :access_token)
    )
  end

  def create_deal(listing)
    properties = {
      "dealname"    => deal_name(listing.listing_number),
      "amount"      => listing.listing_price&.to_s,
      "closedate"   => close_date_ms,
      "description" => listing.summary
    }

    @client.crm.deals.basic_api.create(body: { properties: properties })
  end

  def update_deal(listing)
    @client.crm.deals.basic_api.update(
      deal_id: listing.hubspot_deal_id,
      body: {
        properties: {
          "amount"      => listing.listing_price&.to_s,
          "description" => listing.summary,
          "dealname"    => deal_name(listing.listing_number)
        }
      }
    )
  end

  private

  def deal_name(listing_number)
    "Listing #{listing_number}"
  end

  def close_date_ms
    (30.days.from_now.to_f * 1000).to_i.to_s
  end
end