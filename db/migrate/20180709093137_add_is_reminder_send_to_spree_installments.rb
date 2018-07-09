class AddIsReminderSendToSpreeInstallments < ActiveRecord::Migration
  def change
    add_column :spree_installments, :isReminderSend, :boolean, :default => false
  end
end
