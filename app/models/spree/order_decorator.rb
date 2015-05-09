Spree::Order.class_eval do
  def process_payments!
    create_revised_payments if has_installment_capable_shipments
    process_payments_with(:process!)
  end

  private
    def create_revised_payments
      payment = self.payments.select { |p| p.amount > 0 }.first
      return if payment.nil?

      self.payments.destroy_all

      shipment_amounts = Hash.new
      self.shipments.each do |s|
        shipment_amounts[s.id] = s.installment_capable? ? s.first_installment : s.final_price_with_items
      end

      shipment_id, authorizable_amount = shipment_amounts.max_by { |k,v| v }

      self.payments.create! amount: authorizable_amount,
                            payment_method: payment.payment_method,
                            source: payment.source,
                            state: 'checkout'
    end

    def has_installment_capable_shipments
      self.shipments.select { |s| s.installment_capable? }.any?
    end
end
