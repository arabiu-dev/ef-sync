require 'rails_helper'

RSpec.describe HubspotService do
  describe '#create_deal' do
    let(:listing) do
      instance_double(
        'Listing',
        listing_number: '12345',
        listing_price: 50000,
        summary: 'A great business for sale'
      )
    end

    let(:mock_client)    { double(Hubspot::Client) }
    let(:mock_crm)       { double('Crm') }
    let(:mock_deals)     { double('Deals') }
    let(:mock_basic_api) { double('BasicApi') }

    before do
      allow(Rails.application.credentials).to receive(:dig).with(:hubspot, :access_token).and_return('fake-token')
      allow(Hubspot::Client).to receive(:new).with(access_token: 'fake-token').and_return(mock_client)
      allow(mock_client).to receive(:crm).and_return(mock_crm)
      allow(mock_crm).to receive(:deals).and_return(mock_deals)
      allow(mock_deals).to receive(:basic_api).and_return(mock_basic_api)
      allow(Time).to receive(:now).and_return(Time.zone.local(2026, 3, 21, 12, 0, 0))
    end

    it 'sends the correct properties to the Hubspot API' do
      expected_properties = {
        "dealname"    => "Listing 12345",
        "amount"      => "50000",
        "closedate"   => (30.days.from_now.to_i * 1000).to_s,
        "description" => "A great business for sale"
      }

      expect(mock_basic_api).to receive(:create).with(body: { properties: expected_properties })

      service = described_class.new
      service.create_deal(listing)
    end
  end
end