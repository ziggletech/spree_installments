module Spree
  Payment.class_eval do
    state_machine initial: :checkout do
      # With card payments this represents authorizing the payment
      event :started_processing do
        transition from: [:checkout, :pending, :partial, :completed, :processing], to: :processing
      end
      
      event :part do
        transition from: [:processing, :pending, :checkout], to: :partial
      end
    end
  end
end
