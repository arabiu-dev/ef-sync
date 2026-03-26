class SyncListingsJob
  include Sidekiq::Job

  def perform
    listings_data   = EmpireFlippersService.new.fetch_all_listings
    hubspot_service = HubspotService.new
    results         = { created: 0, updated: 0, failed: 0 }

    listings_data.each do |listing_data|
      begin
        listing = Listing.find_or_initialize_by(
          listing_number: listing_data['listing_number']
        )

        listing.listing_price  = listing_data['listing_price']
        listing.listing_status = listing_data['listing_status']
        listing.summary        = listing_data['summary']
        listing.save!

        if listing.synced_to_hubspot?
          hubspot_service.update_deal(listing)
          results[:updated] += 1
        else
          deal = hubspot_service.create_deal(listing)
          listing.update!(hubspot_deal_id: deal.id)
          results[:created] += 1
        end

      rescue StandardError => e
        results[:failed] += 1
        Rails.logger.error("[SyncListingsJob] Failed for listing ##{listing_data['listing_number']}: #{e.message}")
      end
    end

    Rails.logger.info("[SyncListingsJob] Done — created=#{results[:created]} updated=#{results[:updated]} failed=#{results[:failed]}")
  end
end