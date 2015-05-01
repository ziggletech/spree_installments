module Spree
  class InstallmentPlan < ActiveRecord::Base
    belongs_to :product, class_name: 'Spree::Product'
    belongs_to :shipment, class_name: 'Spree::Shipment'
  end
end
