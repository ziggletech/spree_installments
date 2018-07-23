class ReminderEmailProcessor
    @queue = :installment_email_queue
  
    def self.perform
      due_installments = Spree::Installment.past_due_installment_reminder(Time.zone.now + 1.day)
      due_installments.each do |due_installment|
        InstalmentReminderMailer.reminder_email('test@gmail.com','Installment due').deliver_now;
        due_installment.update_columns(isReminderSend: true);
      end
    end
  end
  