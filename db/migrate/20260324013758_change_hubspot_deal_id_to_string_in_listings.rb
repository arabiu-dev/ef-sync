class ChangeHubspotDealIdToStringInListings < ActiveRecord::Migration[8.1]
  def change
    change_column :listings, :hubspot_deal_id, :string
  end
end
