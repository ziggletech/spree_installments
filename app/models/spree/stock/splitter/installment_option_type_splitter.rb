module Spree
  module Stock
    module Splitter
      class InstallmentOptionTypeSplitter < Spree::Stock::Splitter::Base
        def split(packages)
          split_packages = []
          packages.each do |package|
            split_packages += split_by_installment_option_type(package)
          end
          return_next split_packages
        end

        private
          def split_by_installment_option_type(package)
            categories = Hash.new { |hash, key| hash[key] = [] }
            package.contents.each_with_index do |item, index|
              installment_capable = false
              if option_type = item.variant.product.option_types.find_by(name: Spree::Config[:installment_option_type_name])
                if option_value = item.variant.option_values.find_by(name: Spree::Config[:installment_option_value_name], option_type_id: option_type.id)
                  categories[index] << item
                  installment_capable = true
                end
              end
              categories[package.contents.size + 1] << item unless installment_capable
            end
            hash_to_packages(categories)
          end

          def hash_to_packages(categories)
            packages = []
            categories.each do |id, contents|
              packages << build_package(contents)
            end
            packages
          end

      end
    end
  end
end
