module Spree
  module Stock
    module Splitter
      class InstallmentShippingCategory < Spree::Stock::Splitter::Base
        def split(packages)
          split_packages = []
          packages.each do |package|
            split_packages += split_by_installment_shipping_category(package)
          end
          return_next split_packages
        end

        private
          def split_by_installment_shipping_category(package)
            categories = Hash.new { |hash, key| hash[key] = [] }
            packages = []
            package.contents.each do |item|
              next unless item.variant.shipping_category_id == Spree::Config[:installment_shipping_category_id]
              packages << build_package([item])
            end
            packages
          end

      end
    end
  end
end
