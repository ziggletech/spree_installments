Spree::Shipment.class_eval do
  has_one :installment_plan, class_name: 'Spree::InstallmentPlan', foreign_key: "shipment_id"
end
