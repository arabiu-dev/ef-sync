class SyncListingsJob
  include Sidekiq::Job

  def perform
    listings_data = EmpireFlippersService.new.fetch_all_listings
    hubspot_service = HubspotService.new

    listings_data.each do |listing_data|
      listing = Listing.find_or_initialize_by(
        listing_number: listing_data['listing_number']
      )

      listing.listing_price = listing_data['listing_price']
      listing.listing_status = listing_data['listing_status']
      listing.summary = listing_data['summary']
      listing.save!

      unless listing.hubspot_deal_id.present?
        deal = hubspot_service.create_deal(listing)
        listing.update!(hubspot_deal_id: deal.id)
      end
    end
  end
end