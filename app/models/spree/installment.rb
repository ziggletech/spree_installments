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
      pending_payments =  order.pending_payments
                            .sort_by(&:uncaptured_amount).reverse

      payment = pending_payments.first

      cents = (self.amount * 100).to_i
      if payment.payment_method.type == "Spree::Gateway::BraintreeGateway"
        payment.capture_installment!(cents)
      else
        payment.capture!(cents)
      end
    end
  end
end
