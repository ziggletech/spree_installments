Spree::PaypalController.class_eval do
  private
    def express_checkout_request_details order, items
      { :SetExpressCheckoutRequestDetails => {
          :InvoiceID => order.number,
          :BuyerEmail => order.email,
          :ReturnURL => confirm_paypal_url(:payment_method_id => params[:payment_method_id], :utm_nooverride => 1),
          :CancelURL =>  cancel_paypal_url,
          :SolutionType => payment_method.preferred_solution.present? ? payment_method.preferred_solution : "Mark",
          :LandingPage => payment_method.preferred_landing_page.present? ? payment_method.preferred_landing_page : "Billing",
          :cppheaderimage => payment_method.preferred_logourl.present? ? payment_method.preferred_logourl : "",
          :NoShipping => 1,
          :PaymentDetails => [payment_details(items)],
          :BillingAgreementDetails => [billing_agreement_details]
      }}
    end

    def billing_agreement_details
      {
        :BillingType => "MerchantInitiatedBilling",
        :BillingAgreementDescription => "EZ Pay at DragonDoor"
      }
    end
  
    def payment_details items
      # This retrieves the cost of shipping after promotions are applied
      # For example, if shippng costs $10, and is free with a promotion, shipment_sum is now $10
      shipment_sum = current_order.shipments.map(&:discounted_cost).sum

      # This calculates the item sum based upon what is in the order total, but not for shipping
      # or tax.  This is the easiest way to determine what the items should cost, as that
      # functionality doesn't currently exist in Spree core
      item_sum = current_order.total - shipment_sum - current_order.additional_tax_total

      if item_sum.zero?
        # Paypal does not support no items or a zero dollar ItemTotal
        # This results in the order summary being simply "Current purchase"
        {
          :OrderTotal => {
            :currencyID => current_order.currency,
            :value => current_order.total
          }
        }
      else
        {
          :OrderTotal => {
            :currencyID => current_order.currency,
            :value => current_order.total
          },
          :ItemTotal => {
            :currencyID => current_order.currency,
            :value => item_sum
          },
          :ShippingTotal => {
            :currencyID => current_order.currency,
            :value => shipment_sum,
          },
          :TaxTotal => {
            :currencyID => current_order.currency,
            :value => current_order.additional_tax_total
          },
          :ShipToAddress => address_options,
          :PaymentDetailsItem => items,
          :ShippingMethod => "Shipping Method Name Goes Here",
          :PaymentAction => "Authorization"
        }
      end
    end
end