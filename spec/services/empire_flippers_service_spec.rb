require 'rails_helper'
require 'webmock/rspec'

RSpec.describe EmpireFlippersService do
  describe '#fetch_all_listings' do
    let(:service) { described_class.new }

    before do
      allow(service).to receive(:sleep).and_return(nil)
    end

    it 'fetches for sale listings successfully and returns an array of listings' do
      stub_request(:get, "https://api.empireflippers.com/api/v1/listings/list?limit=100&listing_status=For%20Sale&page=1")
        .to_return(
          status: 200,
          body: { data: { listings: [{ id: 1, listing_number: '12345' }, { id: 2, listing_number: '67890' }] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://api.empireflippers.com/api/v1/listings/list?limit=100&listing_status=For%20Sale&page=2")
        .to_return(
          status: 200,
          body: { data: { listings: [] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.fetch_all_listings
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it 'handles an empty response and returns an empty array' do
      stub_request(:get, "https://api.empireflippers.com/api/v1/listings/list?limit=100&listing_status=For%20Sale&page=1")
        .to_return(
          status: 200,
          body: { data: { listings: [] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.fetch_all_listings
      expect(result).to eq([])
    end

    it 'logs an error and stops on API failure' do
      stub_request(:get, "https://api.empireflippers.com/api/v1/listings/list?limit=100&listing_status=For%20Sale&page=1")
        .to_return(status: 500, body: 'Internal Server Error')

      expect(Rails.logger).to receive(:error).with(/Failed to fetch page 1/)

      result = service.fetch_all_listings
      expect(result).to eq([])
    end

    it 'handles malformed JSON and returns an empty array' do
      stub_request(:get, "https://api.empireflippers.com/api/v1/listings/list?limit=100&listing_status=For%20Sale&page=1")
        .to_return(
          status: 200,
          body: 'NOT JSON',
          headers: { 'Content-Type' => 'application/json' }
        )

      result = service.fetch_all_listings
      expect(result).to eq([])
    end
  end
end