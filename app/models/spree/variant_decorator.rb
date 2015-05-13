Spree::Variant.class_eval do
  has_many :installment_plans, foreign_key: "variant_id"
end
