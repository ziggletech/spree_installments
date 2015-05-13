module Spree
  class InstallmentPlan < ActiveRecord::Base
    belongs_to :product, class_name: 'Spree::Product'
    belongs_to :variant, class_name: 'Spree::Variant'
    belongs_to :shipment, class_name: 'Spree::Shipment'

    has_many :installments, class_name: 'Spree::Installment'
  end
end
