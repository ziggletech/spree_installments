class CreateSpreeInstallments < ActiveRecord::Migration
  def change
    create_table :spree_installments do |t|
      t.references :installment_plan

      t.decimal    :amount, :precision => 8, :scale => 2, :default => 0.0, :null => false
      t.string     :name
      t.date       :due_at
      t.date       :paid_at
      t.string     :state

      t.timestamps
    end
    add_index :spree_installments, :installment_plan_id
  end
end
