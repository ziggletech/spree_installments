Spree::Product.class_eval do
  has_many :installment_plans, foreign_key: "product_id"
end
