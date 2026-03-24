class EmpireFlippersService
  include HTTParty
  base_uri 'https://api.empireflippers.com/api/v1'

  DEFAULT_LIMIT    = 100
  RATE_LIMIT_DELAY = 1.1

  def fetch_all_listings
    page         = 1
    all_listings = []

    loop do
      response = self.class.get("/listings/list", query: {
        page:           page,
        limit:          DEFAULT_LIMIT,
        listing_status: "For Sale"
      })

      if response.success?
        begin
          listings = response.parsed_response.dig('data', 'listings') || []
        rescue JSON::ParserError => e
          Rails.logger.error("[EmpireFlippersService] JSON parse error on page #{page}: #{e.message}")
          break
        end
        break if listings.empty?
        all_listings.concat(listings)
        page += 1
        sleep RATE_LIMIT_DELAY
      else
        Rails.logger.error("[EmpireFlippersService] Failed to fetch page #{page}: #{response.code} #{response.message}")
        break
      end
    end

    all_listings
  end
end