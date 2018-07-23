module Spree
  class Installment < ActiveRecord::Base
    belongs_to :installment_plan, class_name: "Spree::InstallmentPlan"

    scope :due, -> { with_state('pending') }
    scope :paid, -> { with_state('completed') }
    scope :failed, -> { with_state('failed') }

    scope :forEMIProcessing, -> { with_states('pending','processing')}
    scope :forReminderEmail, -> { with_states('pending')}

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

      def self.past_due_installment_capture(date=Time.zone.now)
        forEMIProcessing.where("due_at <= ?", date)
    end

    def self.past_due_installment_reminder(date=Time.zone.now +1.day)
      forReminderEmail.where("due_at <= ?", date).where({isReminderSend: false});
    end

    def capture!
      started_processing!
      shipment = self.installment_plan.shipment
      order = shipment.order
      capture_payment! order.create_shipment_payment(self.amount, order.authorized_payment, shipment.id)
    end

    private
      def capture_payment!(payment)
        if payment.payment_method.type == "Spree::Gateway::PayPalExpress"
          payment.paypal_capture!(self.amount)
        else
          payment.purchase!
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
