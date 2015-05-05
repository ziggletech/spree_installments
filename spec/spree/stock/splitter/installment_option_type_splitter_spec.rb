require 'spec_helper'

module Spree
  module Stock
    module Splitter
      describe InstallmentOptionTypeSplitter, :type => :model do

        let!(:option_type_installment) { create(:option_type, name: 'is-installment') }
        let!(:product) { create(:product) }

        let!(:product_option_type) { create(:product_option_type, :product => product, :option_type => option_type_installment) }

        let!(:variant1) { create(:variant, :product => product) }
        let!(:variant2) { create(:variant, :product => product) }

        let(:shipping_category_1) { create(:shipping_category, name: 'A') }

        let!(:option_value_yes) { create(:option_value, name: 'yes', option_type_id: option_type_installment.id ) }
        let!(:option_value_no) { create(:option_value, name: 'no', option_type_id: option_type_installment.id ) }

        def inventory_unit1
          build(:inventory_unit, variant: variant1).tap do |inventory_unit|
            inventory_unit.variant.product.shipping_category = shipping_category_1
            inventory_unit.variant.option_values << option_value_yes
          end
        end

        def inventory_unit2
          build(:inventory_unit, variant: variant2).tap do |inventory_unit|
            inventory_unit.variant.product.shipping_category = shipping_category_1
            inventory_unit.variant.option_values << option_value_no
          end
        end
        
        let(:packer) { build(:stock_packer) }

        subject { InstallmentOptionTypeSplitter.new(packer) }

        it 'splits each package by option type is-installment == "yes"' do
          package1 = Package.new(packer.stock_location)

          2.times { package1.add inventory_unit1 }
          8.times { package1.add inventory_unit2 }

          package2 = Package.new(packer.stock_location)
          3.times { package2.add inventory_unit1 }
          9.times { package2.add inventory_unit2 }

          packages = subject.split([package1, package2])

          expect(packages[0].quantity).to eq 1
          expect(packages[1].quantity).to eq 1
          expect(packages[2].quantity).to eq 8
          expect(packages[3].quantity).to eq 1
          expect(packages[4].quantity).to eq 1
          expect(packages[5].quantity).to eq 1
          expect(packages[6].quantity).to eq 9
        end
        
      end
    end
  end
end
