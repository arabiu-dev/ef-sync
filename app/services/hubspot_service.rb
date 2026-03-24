class HubspotService
  def initialize
    @client = Hubspot::Client.new(
      access_token: Rails.application.credentials.dig(:hubspot, :access_token)
    )
  end

  def create_deal(listing)
    properties = {
      "dealname" => "Listing #{listing.listing_number}",
      "amount" => listing.listing_price.to_s,
      "closedate" => (30.days.from_now.to_i * 1000).to_s,
      "description" => listing.summary
    }

    @client.crm.deals.basic_api.create(body: { properties: properties })
  end
end