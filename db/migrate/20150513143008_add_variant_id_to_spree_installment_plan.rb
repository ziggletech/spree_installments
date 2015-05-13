class AddVariantIdToSpreeInstallmentPlan < ActiveRecord::Migration
  def change
    add_column :spree_installment_plans, :variant_id, :integer
  end
end
