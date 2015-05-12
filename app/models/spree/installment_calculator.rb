module Spree
  class InstallmentCalculator
    def initialize(total_amount, installment_period=nil, installment_period_span=nil)
      @total_amount = total_amount
      @installment_period = installment_period || Spree::Config[:installment_period]
      @installment_period_span = @installment_period_span || Spree::Config[:installment_period_span]
    end

    def installments
      installment_amount = (@total_amount / @installment_period).round(2)
      installment_total = 0

      installment_amount_pool = (1...@installment_period).each_with_object([]) do |i_period, pool|
        pool << installment_amount
      end

      installment_amount_pool << (@total_amount - installment_amount_pool.sum).round(2)
      installment_amount_pool
    end
  end
end
