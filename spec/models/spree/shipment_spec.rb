require 'spec_helper'

describe Spree::Shipment, :type => :model do
  let(:order) { mock_model Spree::Order, backordered?: false,
                                         canceled?: false,
                                         can_ship?: true,
                                         currency: 'USD',
                                         number: 'S12345',
                                         paid?: false,
                                         touch: true }
  let(:shipping_method) { create(:shipping_method, name: "UPS") }
  let(:option_type_installment) { create(:option_type, name: 'is-installment', presentation: "Is Installment") }
  let(:product) { create(:product) }

  let!(:product_option_type) { create(:product_option_type, :product => product, :option_type => option_type_installment) }

  let!(:option_value_yes) { create(:option_value, name: 'yes', presentation: "Yes", option_type_id: option_type_installment.id ) }
  let!(:option_value_no) { create(:option_value, name: 'no', presentation: "No", option_type_id: option_type_installment.id ) }

  let(:variant1) { create(:variant, :product => product, option_value_ids: [option_value_yes.id]) }
  let(:variant2) { create(:variant, :product => product) }

  let(:line_item_yes) { mock_model(Spree::LineItem, variant: variant1) }
  let(:line_item_no) { mock_model(Spree::LineItem, variant: variant2) }

  let(:shipment) do
    shipment = Spree::Shipment.new(cost: 1, state: 'pending', stock_location: create(:stock_location))
    allow(shipment).to receive_messages order: order
    allow(shipment).to receive_messages shipping_method: shipping_method
    shipment.save
    shipment
  end

  context '#installment_capable' do
    it "retuns true if has installment capable variant" do
      shipment.inventory_units.build(
        pending: true,
        variant: line_item_yes.variant,
        line_item: line_item_yes,
        order: order
      )
      shipment.save
      expect(shipment.installment_capable?).to be true
    end
    
    it "retuns nil if has not installment capable variant" do
      shipment.inventory_units.build(
        pending: true,
        variant: line_item_no.variant,
        line_item: line_item_no,
        order: order
      )
      shipment.save
      expect(shipment.installment_capable?).to be_falsy
    end
  end
end
