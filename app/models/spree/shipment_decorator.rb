Spree::Shipment.class_eval do
  has_one :installment_plan, class_name: 'Spree::InstallmentPlan', foreign_key: "shipment_id"

  def process_order_payments
    if installment_capable?
      process_installment_order_payments
    else
      process_non_installment_order_payments
    end
  end

  private
    def process_installment_order_payments
      create_installment_plan
      # TODO: installments creation might not be needed as we will manage them one
      # recurring profile are created.
      create_installments
      capture_first_installment!
    end

    def process_non_installment_order_payments
      pending_payments =  order.pending_payments
                            .sort_by(&:uncaptured_amount).reverse

      # NOTE Do we really need to force orders to have pending payments on dispatch?
      if pending_payments.empty?
        raise Spree::Core::GatewayError, Spree.t(:no_pending_payments)
      else
        shipment_to_pay = final_price_with_items
        payments_amount = 0

        payments_pool = pending_payments.each_with_object([]) do |payment, pool|
          next if payments_amount >= shipment_to_pay
          payments_amount += payment.uncaptured_amount
          pool << payment
        end

        payments_pool.each do |payment|
          capturable_amount = if payment.amount >= shipment_to_pay
                                shipment_to_pay
                              else
                                payment.amount
                              end
          # cents = (capturable_amount * 100).to_i
          payment.capture!(capturable_amount, true)
          shipment_to_pay -= capturable_amount
        end
      end
    rescue Spree::Core::GatewayError => e
      errors.add(:base, e.message)
      return !!Spree::Config[:allow_checkout_on_gateway_error]
    end

    def installment_capable?
      inventory_units.includes(:variant)
        .map(&:variant).map(&:shipping_category_id)
        .include?(Spree::Config[:installment_shipping_category_id])
    end

    def create_installment_plan
      shipment_to_pay = final_price_with_items
      installment_period = Spree::Config[:installment_period]
      installment_period_span = Spree::Config[:installment_period_span]

      # assume that installment capable product can have individual shipment.
      # This can be handled in shipment splitter
      # TODO: discussion with Dan
      variant_product = inventory_units.includes(:variant).first.variant.product

      # TODO: create plan on braintree before_create
      self.create_installment_plan!({
        product_id: variant_product.id,
        email: self.order.email,
        period: installment_period,
        period_span: installment_period_span,
        amount: shipment_to_pay
      })
    end

    def create_installments
      shipment_to_pay = final_price_with_items
      installment_period = Spree::Config[:installment_period]
      installment_period_span = Spree::Config[:installment_period_span]
      installment_amount = (shipment_to_pay / installment_period).round(2)
      installment_total = 0

      installment_amount_pool = (1...installment_period).each_with_object([]) do |i_period, pool|
        pool << installment_amount
      end

      installment_amount_pool << (shipment_to_pay - installment_amount_pool.sum).round(2)

      installment_amount_pool.each_with_index do |inst_amount, index|
        self.installment_plan.installments.create({
          name: "Installment #{index+1} : #{inst_amount}",
          amount: inst_amount,
          due_at: Time.now + (index * installment_period_span).days
        })
      end
    end

    def capture_first_installment!
      self.installment_plan.installments.first.capture!
    end

end
