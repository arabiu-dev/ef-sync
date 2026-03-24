class EmpireFlippersService
  include HTTParty
  base_uri 'https://api.empireflippers.com/api/v1'

  def fetch_all_listings
    page = 1
    all_listings = []

    loop do
      response = self.class.get("/listings/list", query: {
        page: page,
        limit: 100,
        listing_status: "For Sale"
      })

      if response.success?
        listings = response.parsed_response.dig('data', 'listings') || []
        break if listings.empty?
        all_listings.concat(listings)
        page += 1
        sleep 1
      else
        Rails.logger.error("Failed to fetch page #{page}: #{response.code}")
        break
      end
    end

    all_listings
  end
end