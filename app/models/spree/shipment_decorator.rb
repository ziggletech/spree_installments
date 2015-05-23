Spree::Shipment.class_eval do
  has_many :payments, class_name: 'Spree::Payment', foreign_key: "shipment_id"
  has_one :installment_plan, class_name: 'Spree::InstallmentPlan', foreign_key: "shipment_id"

  def process_order_payments
    if installment_capable?
      process_installment_order_payments
    else
      process_non_installment_order_payments
    end
  end

  def installment_capable?
    if option_type = Spree::OptionType.find_by(name: Spree::Config[:installment_option_type_name])
      return inventory_units.size == 1 && !inventory_units.first.variant.option_values.find_by(name: Spree::Config[:installment_option_value_name], option_type_id: option_type.id).nil?
    end
  end

  def first_installment
    return self.installment_plan.installments.first if self.installment_plan && self.installment_plan.installments.any?
    Spree::InstallmentCalculator.new(self.final_price_with_items).installments.first
  end

  def pending_shipment_payments
    order.pending_payments
      .select { |payment| payment.shipment_id == self.id }
      .sort_by(&:uncaptured_amount).reverse
  end

  private
    def process_installment_order_payments
      create_installment_plan
      create_installments
      capture_first_installment!
    end

    def process_non_installment_order_payments
      pending_payments =  order.pending_payments
                            .sort_by(&:uncaptured_amount).reverse


      shipment_to_pay = final_price_with_items
      payments_amount = 0

      if pending_payments.empty?
        purchase_payment!
      else
        payments_pool = pending_payments.each_with_object([]) do |payment, pool|
          break if payments_amount >= shipment_to_pay
          payments_amount += payment.uncaptured_amount
          pool << payment
        end

        payments_pool.each do |payment|
          capturable_amount = if payment.amount >= shipment_to_pay
                                shipment_to_pay
                              else
                                payment.amount
                              end

          capture_payment!(payment, capturable_amount)
          shipment_to_pay -= capturable_amount
        end
      end
    end

    def purchase_payment!
      # create new payment and do purchase
      shipment_to_pay = final_price_with_items
      payment = order.create_shipment_payment(shipment_to_pay, order.authorized_payment, self.id)
      capture_payment!(payment, shipment_to_pay, "sale")
    end

    def capture_payment!(payment, capturable_amount, transaction_type=nil)
      if payment.payment_method.type == "Spree::Gateway::PayPalExpress"
        payment.paypal_capture!(capturable_amount)
      else
        if transaction_type == "sale"
          payment.purchase!
        else
          cents = (capturable_amount * 100).to_i
          payment.capture!(cents)

          # do purchase if capture fails
          purchase_payment! if payment.failed?
        end
      end
    end

    def create_installment_plan
      shipment_to_pay = final_price_with_items
      installment_period = Spree::Config[:installment_period]
      installment_period_span = Spree::Config[:installment_period_span]

      variant = inventory_units.includes(:variant).first.variant

      self.create_installment_plan!({
        product_id: variant.product.id,
        variant_id: variant.id,
        email: self.order.email,
        period: installment_period,
        period_span: installment_period_span,
        amount: shipment_to_pay
      })
    end

    def create_installments
      installment_amount_pool = Spree::InstallmentCalculator.new(self.final_price_with_items).installments
      installment_period_span = Spree::Config[:installment_period_span]

      installment_amount_pool.each_with_index do |inst_amount, index|
        self.installment_plan.installments.create({
          name: "Installment #{index+1} : #{inst_amount}",
          amount: inst_amount,
          due_at: Time.zone.now + (index * installment_period_span).days
        })
      end
    end

    def capture_first_installment!
      self.installment_plan.installments.first.capture!
    end

end
