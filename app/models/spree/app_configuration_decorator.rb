Spree::AppConfiguration.class_eval do
  preference :installment_period, :integer, default: 3 # amount will be divided by this number
  preference :installment_period_span, :integer, default: 30 # in days
  preference :installment_option_type_name, :string, default: 'is-installment'
  preference :installment_option_value_name, :string, default: 'yes' # in days
end
