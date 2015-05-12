class AddShipmentIdToSpreePayments < ActiveRecord::Migration
  def change
    t.references :shipment
  end
end
