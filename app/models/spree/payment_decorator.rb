Spree::Payment.class_eval do
  def paypal_capture!(amount = nil)
    return true if completed?
    started_processing!
    protect_from_connection_error do
      # Standard ActiveMerchant capture usage
      response = payment_method.capture(
        amount,
        response_code,
        gateway_options
      )
      capture_events.create!(amount: amount)
      split_uncaptured_amount
      handle_response(response, :complete, :failure)
    end
  end
end
