class CreateSpreeInstallmentPlans < ActiveRecord::Migration
  def change
    create_table :spree_installment_plans do |t|
      t.references :product
      t.references :shipment
      t.decimal    :amount, :precision => 8, :scale => 2, :default => 0.0, :null => false
      t.string     :email
      t.string     :state
      t.integer    :period
      t.integer    :period_span

      t.timestamps
    end
  end
end
