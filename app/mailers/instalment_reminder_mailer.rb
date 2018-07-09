class InstalmentReminderMailer < ApplicationMailer
    default from: 'mailerTest@example.com'

    def reminder_email(mailTo,subject)
        mail(to: mailTo , subject: subject)
      end
end
