require 'rails_helper'

RSpec.describe HubspotService do
  subject(:service) { described_class.new }

  let(:mock_client)    { double('hubspot_client') }
  let(:mock_crm)       { double('crm') }
  let(:mock_deals)     { double('deals') }
  let(:mock_basic_api) { double('basic_api') }
  let(:fake_deal)      { double('fake_deal', id: 'hs-deal-123') }

  before do
    allow(Rails.application.credentials).to receive(:dig)
      .with(:hubspot, :access_token)
      .and_return('fake-token')
    allow(Hubspot::Client).to receive(:new).with(access_token: 'fake-token').and_return(mock_client)
    allow(mock_client).to receive(:crm).and_return(mock_crm)
    allow(mock_crm).to receive(:deals).and_return(mock_deals)
    allow(mock_deals).to receive(:basic_api).and_return(mock_basic_api)
    allow(mock_basic_api).to receive(:create).and_return(fake_deal)
  end

  describe '#create_deal' do
    let(:listing) do
      instance_double(
        'Listing',
        listing_number: 12345,
        listing_price:  50000,
        summary:        'A great business for sale'
      )
    end

    it 'creates a deal and returns it' do
      expect(mock_basic_api).to receive(:create).and_return(fake_deal)
      result = service.create_deal(listing)
      expect(result.id).to eq('hs-deal-123')
    end

    it 'sends the correct deal name' do
      expect(mock_basic_api).to receive(:create) do |args|
        props = args[:body][:properties]
        expect(props['dealname']).to eq('Listing 12345')
        fake_deal
      end
      service.create_deal(listing)
    end

    it 'sends the correct amount' do
      expect(mock_basic_api).to receive(:create) do |args|
        props = args[:body][:properties]
        expect(props['amount']).to eq('50000')
        fake_deal
      end
      service.create_deal(listing)
    end

    it 'sends the correct description' do
      expect(mock_basic_api).to receive(:create) do |args|
        props = args[:body][:properties]
        expect(props['description']).to eq('A great business for sale')
        fake_deal
      end
      service.create_deal(listing)
    end

    it 'raises an error when Hubspot API fails' do
      allow(mock_basic_api).to receive(:create).and_raise(StandardError.new('Hubspot error'))
      expect { service.create_deal(listing) }.to raise_error(StandardError, 'Hubspot error')
    end
  end
end