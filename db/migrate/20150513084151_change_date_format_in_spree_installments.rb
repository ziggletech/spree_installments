class ChangeDateFormatInSpreeInstallments < ActiveRecord::Migration
  def up
    change_column :spree_installments, :due_at, :datetime
    change_column :spree_installments, :paid_at, :datetime
  end

  def down
    change_column :spree_installments, :due_at, :date
    change_column :spree_installments, :paid_at, :date
  end
end
