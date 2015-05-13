module Spree
  class Installment < ActiveRecord::Base
    belongs_to :installment_plan, class_name: "Spree::InstallmentPlan"

    scope :due, -> { with_state('pending') }
    scope :paid, -> { with_state('completed') }
    scope :failed, -> { with_state('failed') }

    state_machine :state, initial: :pending do
      event :failure do
        transition from: [:pending, :processing], to: :failed
      end

      event :started_processing do
        transition from: [:pending, :failed], to: :processing
      end

      event :complete do
        transition from: [:processing, :pending], to: :completed
      end
    end

    def self.past_due(date=Time.zone.now)
      due.where("due_at <= ?", date)
    end

    def capture!
      started_processing!
      shipment = self.installment_plan.shipment
      order = shipment.order
      shipment_payments = shipment.pending_shipment_payments

      unless shipment_payments.any?
        payment = order.create_shipment_payment(self.amount, shipment.authorized_payment, shipment.id)
        payment.purchase!
      else
        payment = shipment_payments.first
        cents = (self.amount * 100).to_i

        if payment.payment_method.type == "Spree::Gateway::BraintreeGateway"
          payment.capture_installment!(cents)
        else
          payment.capture!(cents)
        end
      end

      if payment.completed?
        self.update_column(:paid_at, Time.zone.now)
        complete!
      else
        failure!
      end

    end
  end
end
