class Listing < ApplicationRecord
  validates :listing_number, presence: true, uniqueness: true
  validates :listing_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :without_deal, -> { where(hubspot_deal_id: nil) }

  def synced_to_hubspot?
    hubspot_deal_id.present?
  end
end