class InstallmentProcessor
  @queue = :installment_queue

  def self.perform
    capture_due
    capture_failed
  end

  private
    def capture_due
      due_installments = Spree::Installment.past_due(Time.zone.now)
      due_installments.each do |due_installment|
        due_installment.capture!
      end
    end

    def capture_failed
      failed = Spree::Installment.failed
      failed.each do |failed_installment|
        failed_installment.capture!
      end
    end
end
