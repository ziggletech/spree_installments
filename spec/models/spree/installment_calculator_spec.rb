require 'spec_helper'

module Spree
  describe InstallmentCalculator, :type => :model do
    
    context "#installments" do
      it "sum should equal to total amount" do
        installmets = Spree::InstallmentCalculator.new(1000.00).installments
        expect(installmets.sum).to eq(1000.00)
        expect(installmets.first).to eq(333.33)
        expect(installmets.last).to eq(333.34)
      end
    end    
  end
end
