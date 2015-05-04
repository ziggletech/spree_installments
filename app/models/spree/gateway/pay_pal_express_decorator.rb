Spree::Gateway::PayPalExpress.class_eval do

  # We need to override this method as spree_paypal_express set its value to true by default
  def auto_capture?
    Spree::Config[:auto_capture]
  end

  def authorize(amount, express_checkout, gateway_options={})
    do_action "Authorization", express_checkout, gateway_options
  end

  def purchase(amount, express_checkout, gateway_options={})
    do_action "Sale", express_checkout, gateway_options
  end

  def make_recurring(installment, installment_plan, express_checkout)
    pp_request = provider.build_create_recurring_payments_profile(create_recurring_profile_request_details(installment, installment_plan, express_checkout))
    byebug
    pp_response = provider.create_recurring_payments_profile(pp_request)
    if pp_response.success?
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

  def capture(amount, express_checkout, gateway_options={})
    pp_details_request = provider.build_do_capture({
      :AuthorizationID => express_checkout.transaction_id,
      :Amount => {
          :currencyID => gateway_options[:currency],
          :value => amount },
      :CompleteType => "NotComplete"
    })

    pp_response = provider.do_capture(pp_details_request)
    if pp_response.success?
      # transaction id is already stored when payment is authorized. so do nothing here
      # example response for transaction_id = 9K62973311046611B represented as AuthorizationID ii response
      # {"Timestamp"=>"2015-05-04T07:34:27Z", "Ack"=>"Success", "CorrelationID"=>"4a08b89597659", "Version"=>"106.0", "Build"=>"16481822", "DoCaptureResponseDetails"=>{"AuthorizationID"=>"9K62973311046611B", "PaymentInfo"=>{"TransactionID"=>"91Y885745C368774X", "ParentTransactionID"=>"9K62973311046611B", "ReceiptID"=>nil, "TransactionType"=>"cart", "PaymentType"=>"instant", "PaymentDate"=>"2015-05-04T07:34:27Z", "GrossAmount"=>{"@currencyID"=>"USD", "value"=>"27.99"}, "FeeAmount"=>{"@currencyID"=>"USD", "value"=>"1.11"}, "TaxAmount"=>{"@currencyID"=>"USD", "value"=>"1.15"}, "ExchangeRate"=>nil, "PaymentStatus"=>"Completed", "PendingReason"=>"none", "ReasonCode"=>"none", "ProtectionEligibility"=>"Ineligible", "ProtectionEligibilityType"=>"None"}}}

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
    def create_recurring_profile_request_details(installment, installment_plan, express_checkout)
      {
        :CreateRecurringPaymentsProfileRequestDetails => {
          :Token => express_checkout.token,
          :PayerID => express_checkout.payer_id,
          :RecurringPaymentsProfileDetails => {
            :BillingStartDate => Time.zone.now },
          :ScheduleDetails => {
            :Description => installment_plan.product.name,
            :PaymentPeriod => {
              :BillingPeriod => "Month", # installment_plan.period
              :BillingFrequency => 3, # # installment_plan.period_span
              :Amount => {
                :currencyID => "USD",
                :value => installment.amount } },
            :MaxFailedPayments => 3,
            :ActivationDetails => {
              :FailedInitialAmountAction => "ContinueOnFailure" },
            :AutoBillOutstandingAmount => "NoAutoBill" } } }
    end

    def do_action(payment_action, express_checkout, gateway_options)
      byebug
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
