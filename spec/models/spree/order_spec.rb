require 'spec_helper'

describe Spree::Order, :type => :model do

  context "#has_installment_capable_shipments" do

    before do
      Spree::Config[:auto_capture_on_dispatch] = true
      @order = create :completed_order_with_pending_payment
      @shipment = @order.shipments.first
      allow(@shipment).to receive_messages installment_capable?: true
    end
    
    it "return true if it has installment capable shipment" do
      expect(@order.has_installment_capable_shipments).to be true
    end

    context 'with Config.auto_capture_on_dispatch == true' do

      it "should create revised payments" do
        expect(@order).to receive(:create_revised_payments)
        @order.process_payments!
      end
    end

  end
end
