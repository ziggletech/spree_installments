class AddShipmentIdToSpreePayments < ActiveRecord::Migration
  def change
    add_column :spree_payments, :shipment_id, :integer
  end
end
