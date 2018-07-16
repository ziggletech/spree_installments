Spree::Admin::OrdersController.class_eval do
    def captureInstalment
        #session[:return_to] ||= request.referer
           @id = params[:id]
            
           installment =  Spree::Installment.find_by_id(@id)
           installment.capture!
        redirect_to request.referer
      end

      def captureAllInstallments
        #session[:return_to] ||= request.referer
           @id = params[:id]
           amountToBeCaptured = 0.00
           installmentPlan =  Spree::InstallmentPlan.find_by_id(@id)
           shipment = installmentPlan.shipment
           order = shipment.order
           installmentPlan.installments.where("paid_at IS NULL").each do |installment|
            amountToBeCaptured = amountToBeCaptured + installment.amount
           end
           
           payment = order.create_shipment_payment(amountToBeCaptured, order.authorized_payment, shipment.id)

           payment.purchase!

          if payment.completed?
            installmentPlan.installments.where("paid_at IS NULL").each do |installment|
                installment.update_column(:paid_at, Time.zone.now)
                installment.update_column(:state, "completed")
               end
          else
            installmentPlan.installments.where("paid_at IS NULL").each do |installment|
                installment.update_column(:state, "failed")
               end
          end

        redirect_to request.referer
      end
      
end