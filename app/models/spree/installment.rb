module Spree
  class Installment < ActiveRecord::Base
    belongs_to :installment_plan, class_name: "Spree::InstallmentPlan"

    scope :due, -> { with_state('due') }
    scope :paid, -> { with_state('paid') }

    state_machine :state, initial: :due do
      event :failure do
        transition from: [:due], to: :failed
      end
      event :capture do
        transition from: [:due], to: [:paid]
      end
      before_transition to: :paid, do: :before_paid
      after_transition to: :paid, do: :after_paid
    end

    def self.past_due(date)
      due.where("due_at <= ?", date)
    end

    def after_paid
      self.update_column(:paid_at, Time.now)
    end

    def before_paid
      order = self.installment_plan.shipment.order
      pending_payments = order.payments.sort_by(&:uncaptured_amount).reverse

      # NOTE Do we really need to force orders to have pending payments on dispatch?
      if pending_payments.empty?
        raise Spree::Core::GatewayError, Spree.t(:no_pending_payments)
      else
        payment = pending_payments.first
        # cents = (self.amount * 100).to_i

        # TODO: paypal except payment in normal amount. See this in case of braintree also.
        # Normall cents are passed.
        payment.capture!(self.amount, true)

        # WIP: creating recurring profile after first capture
        payment.payment_method.make_recurring(self, self.installment_plan, payment.source)
      end
    rescue Spree::Core::GatewayError => e
      # TODO: record failure report
      errors.add(:base, e.message)
      return !!Spree::Config[:allow_checkout_on_gateway_error]
    end
  end
end
