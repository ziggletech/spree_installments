Spree::Payment.class_eval do

  def capture_installment!(amount)
    return true if completed?
    started_processing!
    protect_from_connection_error do
      check_environment
      response = payment_method.send(:purchase, amount,
                                     source,
                                     gateway_options)

      money = ::Money.new(amount, currency)
      capture_events.create!(amount: money.to_f)
      split_uncaptured_amount
      handle_response(response, :complete, :failure)
    end
  end
end
