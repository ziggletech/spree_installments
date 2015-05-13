Spree::Order.class_eval do
  def process_payments!
    create_revised_payments if Spree::Config['auto_capture_on_dispatch'] && has_installment_capable_shipments
    # authorize or capture revised payment
    process_payments_with(:process!)
  end

  def create_shipment_payment(amount, payment, shipment_id)
    self.payments.create! amount: amount,
                          avs_response: payment.avs_response,
                          cvv_response_code: payment.cvv_response_code,
                          cvv_response_message: payment.cvv_response_message,
                          response_code: payment.response_code,
                          payment_method: payment.payment_method,
                          source: payment.source,
                          shipment_id: shipment_id,
                          state: 'checkout'
  end

  def has_installment_capable_shipments
    self.shipments.select { |s| s.installment_capable? }.any?
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
      create_shipment_payment(authorizable_amount, payment, shipment_id)
    end

end
