require 'rails_helper'

RSpec.describe SyncListingsJob, type: :job do
  describe '#perform' do
    let(:empire_flippers_service) { instance_double(EmpireFlippersService) }
    let(:hubspot_service) { instance_double(HubspotService) }

    before do
      allow(EmpireFlippersService).to receive(:new).and_return(empire_flippers_service)
      allow(HubspotService).to receive(:new).and_return(hubspot_service)
    end

    context 'when listing does not exist' do
      let(:api_listing) do
        {
          'listing_number' => 1001,
          'listing_price'  => 50000,
          'listing_status' => 'For Sale',
          'summary'        => 'Great e-commerce business'
        }
      end

      before do
        allow(empire_flippers_service).to receive(:fetch_all_listings).and_return([api_listing])
      end

      it 'creates a new listing and a HubSpot deal' do
        hubspot_deal = double('HubspotDeal', id: '123')
        expect(hubspot_service).to receive(:create_deal)
          .with(an_instance_of(Listing))
          .and_return(hubspot_deal)

        expect {
          described_class.new.perform
        }.to change(Listing, :count).by(1)

        listing = Listing.find_by(listing_number: 1001)
        expect(listing.listing_price).to eq(50000)
        expect(listing.listing_status).to eq('For Sale')
        expect(listing.summary).to eq('Great e-commerce business')
        expect(listing.hubspot_deal_id).to eq('123')
      end
    end

    context 'when listing already exists with a hubspot_deal_id' do
      let!(:existing_listing) do
        Listing.create!(
          listing_number:  1002,
          listing_price:   30000,
          listing_status:          'Pending',
          summary:         'Old summary',
          hubspot_deal_id: '456'
        )
      end

      let(:api_listing) do
        {
          'listing_number' => 1002,
          'listing_price'  => 35000, # Price changed
          'listing_status' => 'For Sale', # Status changed
          'summary'        => 'Updated summary' # Summary changed
        }
      end

      before do
        allow(empire_flippers_service).to receive(:fetch_all_listings).and_return([api_listing])
      end

      it 'updates existing listing data and skips creating a HubSpot deal' do
        # Expect create_deal NOT to be called
        expect(hubspot_service).not_to receive(:create_deal)

        expect {
          described_class.new.perform
        }.not_to change(Listing, :count)

        existing_listing.reload
        expect(existing_listing.listing_price).to eq(35000)
        expect(existing_listing.listing_status).to eq('For Sale')
        expect(existing_listing.summary).to eq('Updated summary')
        expect(existing_listing.hubspot_deal_id).to eq('456')
      end
    end

    context 'when listing exists but has no hubspot_deal_id' do
      let!(:existing_listing) do
        Listing.create!(
          listing_number:  1003,
          listing_price:   40000,
          listing_status:          'For Sale',
          summary:         'Pending business',
          hubspot_deal_id: nil
        )
      end

      let(:api_listing) do
        {
          'listing_number' => 1003,
          'listing_price'  => 40000,
          'listing_status' => 'For Sale',
          'summary'        => 'Pending business'
        }
      end

      before do
        allow(empire_flippers_service).to receive(:fetch_all_listings).and_return([api_listing])
      end

      it 'creates a HubSpot deal for the existing listing' do
        hubspot_deal = double('HubspotDeal', id: '123')
        expect(hubspot_service).to receive(:create_deal)
          .with(existing_listing)
          .and_return(hubspot_deal)

        expect {
          described_class.new.perform
        }.not_to change(Listing, :count)

        existing_listing.reload
        expect(existing_listing.hubspot_deal_id).to eq('123')
      end
    end
  end
end