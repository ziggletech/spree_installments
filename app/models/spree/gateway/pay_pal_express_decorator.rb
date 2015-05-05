Spree::Gateway::PayPalExpress.class_eval do

  # We need to override this method as spree_paypal_express set its value to true by default
  def auto_capture?
    Spree::Config[:auto_capture]
  end

  def authorize(amount, express_checkout, gateway_options={})
    pp_request = provider.build_create_billing_agreement({
      :Token => express_checkout.token
    })
    pp_response = provider.create_billing_agreement(pp_request)

    if pp_response.success?
      # We need to store the reference id for the future.
      # This is mainly so we can use it later on to capture the payment.
      reference_id = pp_response.billing_agreement_id
      # This is rather hackish, required for payment/processing handle_response code.
      ActiveMerchant::Billing::Response.new(true, 'SpreeGatewayPayPalExpress: success', {}, :authorization => reference_id)
      # Class.new do
#         def initialize(reference_id)
#           @reference_id = reference_id
#         end
#         def success?; true; end
#         def authorization; @reference_id; end
#       end.new(reference_id)
    else
      class << pp_response
        def to_s
          errors.map(&:long_message).join(" ")
        end
      end
      pp_response
    end
  end

  def purchase(amount, express_checkout, gateway_options={})
    do_action "Sale", express_checkout, gateway_options
  end

  def capture(amount, auth_code, gateway_options={})
    pp_details_request = provider.build_do_reference_transaction({
      :DoReferenceTransactionRequestDetails => {
        :ReferenceID => auth_code,
        :PaymentAction => "Sale",
        :PaymentDetails => {
          :OrderTotal => {
            :currencyID => gateway_options[:currency],
            :value => amount
          }
        }
      }
    })

    pp_response = provider.do_reference_transaction(pp_details_request)
    if pp_response.success?
      # This is rather hackish, required for payment/processing handle_response code.
      Class.new do
        def success?; true; end
        def authorization; nil; end
      end.new
    else
      class << pp_response
        def to_s
          errors.map(&:long_message).join(" ")
        end
      end
      pp_response
    end
  end

  private
    def do_action(payment_action, express_checkout, gateway_options)
      pp_details_request = provider.build_get_express_checkout_details({
        :Token => express_checkout.token
      })
      pp_details_response = provider.get_express_checkout_details(pp_details_request)

      pp_request = provider.build_do_express_checkout_payment({
        :DoExpressCheckoutPaymentRequestDetails => {
          :PaymentAction => payment_action,
          :Token => express_checkout.token,
          :PayerID => express_checkout.payer_id,
          :PaymentDetails => pp_details_response.get_express_checkout_details_response_details.PaymentDetails
        }
      })

      pp_response = provider.do_express_checkout_payment(pp_request)
      if pp_response.success?
        # We need to store the transaction id for the future.
        # This is mainly so we can use it later on to refund the payment if the user wishes.
        transaction_id = pp_response.do_express_checkout_payment_response_details.payment_info.first.transaction_id
        express_checkout.update_column(:transaction_id, transaction_id)
        # This is rather hackish, required for payment/processing handle_response code.
        Class.new do
          def success?; true; end
          def authorization; nil; end
        end.new
      else
        class << pp_response
          def to_s
            errors.map(&:long_message).join(" ")
          end
        end
        pp_response
      end
    end
end
