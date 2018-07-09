class ReminderEmailProcessor
    @queue = :installment_email_queue
  
    def self.perform
      due_installments = Spree::Installment.past_due_email(Time.zone.now)
      due_installments.each do |due_installment|
        InstalmentReminderMailer.reminder_email('test@gmail.com','Installment due').deliver_now
      end
    end
  end
  