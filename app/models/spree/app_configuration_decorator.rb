Spree::AppConfiguration.class_eval do
  preference :installment_period, :integer, default: 3 # amount will be divided by this number
  preference :installment_period_span, :integer, default: 30 # in days
  preference :installment_shipping_category_id, :integer, default: 2 # in days
end
