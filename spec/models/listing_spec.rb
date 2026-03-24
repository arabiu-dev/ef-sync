require 'rails_helper'

RSpec.describe Listing, type: :model do
  describe 'validations' do
    it 'is valid with a unique listing_number' do
      listing = build(:listing)
      expect(listing).to be_valid
    end

    it 'is invalid without a listing_number' do
      listing = build(:listing, listing_number: nil)
      expect(listing).not_to be_valid
      expect(listing.errors[:listing_number]).to include("can't be blank")
    end

    it 'is invalid with a duplicate listing_number' do
      create(:listing, listing_number: 70001)
      duplicate = build(:listing, listing_number: 70001)
      expect(duplicate).not_to be_valid
    end

    it 'is invalid with a negative listing_price' do
      listing = build(:listing, listing_price: -1)
      expect(listing).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:for_sale_listing) { create(:listing, listing_status: 'For Sale') }
    let!(:with_deal)        { create(:listing, hubspot_deal_id: 'hs-deal-123') }

    it '.without_deal returns listings with no hubspot_deal_id' do
      expect(Listing.without_deal).to include(for_sale_listing)
      expect(Listing.without_deal).not_to include(with_deal)
    end
  end

  describe '#synced_to_hubspot?' do
    it 'returns true when hubspot_deal_id is present' do
      listing = build(:listing, hubspot_deal_id: 'hs-deal-123')
      expect(listing).to be_synced_to_hubspot
    end

    it 'returns false when hubspot_deal_id is nil' do
      listing = build(:listing, hubspot_deal_id: nil)
      expect(listing).not_to be_synced_to_hubspot
    end
  end
end