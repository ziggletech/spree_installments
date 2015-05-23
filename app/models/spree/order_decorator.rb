Spree::Order.class_eval do
  def process_payments!
    create_revised_payments if Spree::Config['auto_capture_on_dispatch']
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

  def authorized_payment
    pending_payments = self.pending_payments.sort_by(&:uncaptured_amount).reverse
    return pending_payments.first unless pending_payments.empty?
    self.payments.select { |payment| payment.completed? }.sort_by(&:updated_at).reverse.first
  end

  def has_installment_capable_shipments
    self.shipments.select { |s| s.installment_capable? }.any?
  end

  def has_non_installment_capable_shipments
    self.shipments.select { |s| !s.installment_capable? }.any?
  end

  private
    def create_revised_payments
      payment = self.payments.select { |p| p.amount > 0 }.first
      return if payment.nil?

      # Installment shipment will never be authorized/captured. They will always charged with "Sale".
      # In case of installment always authorize only $1
      # If order has any non installment shipments than authorize for max shipment. And others will be charged with "Sale"

      # You are here that mean order has installments
      # Now check if order has any non installments
      # if yes
      #   than find max of all non installment shipments and authorize it
      # if no
      #   than authorize for $1 only
      shipment_id, authorizable_amount = self.shipments.first.id, 1

      if has_non_installment_capable_shipments
        shipment_amounts = Hash.new
        self.shipments.each do |s|
          next if s.installment_capable?
          shipment_amounts[s.id] = s.final_price_with_items
        end
        shipment_id, authorizable_amount = shipment_amounts.max_by { |k,v| v }
      end

      self.payments.destroy_all
      create_shipment_payment(authorizable_amount, payment, shipment_id)
    end

end
