Spree::Admin::OrdersController.class_eval do
    def captureInstalment
        #session[:return_to] ||= request.referer
           @id = params[:id]
            
           installment =  Spree::Installment.find_by_id(@id)
           installment.capture!
        redirect_to request.referer
      end
end