require 'spec_helper'

RSpec.describe "Checkout" do

  context "paypal payment method" do
    let(:order) { Spree::TestingSupport::OrderWalkthrough.up_to(:payment) }
    let(:paypal_payment_method) { create(:paypal_payment_method) }

    before do
      user = create(:user)
      order.user = user
      order.recalculate

      paypal_payment_method
      allow_any_instance_of(Spree::CheckoutController).to receive_messages(current_order: order, try_spree_current_user: user)
    end

    it "should generate a js file with the correct credentials and intent attached" do
      visit '/checkout/payment'
      expect(page).to have_css(
        'script[src*="sdk/js?client-id=' + paypal_payment_method.preferences[:client_id] + '&intent=authorize"]', visible: false
        )
    end

    context "when auto-capture is set to true" do
      it "should generate a js file with intent capture" do
        paypal_payment_method.update(auto_capture: true)
        visit '/checkout/payment'
        expect(page).to have_css(
          'script[src*="sdk/js?client-id=' + paypal_payment_method.preferences[:client_id] + '&intent=capture"]', visible: false
          )
      end
    end

    context "if no payment has been made" do
      it "should fail to process" do
        visit '/checkout/payment'
        choose(option: paypal_payment_method.id)
        click_button("Save and Continue")
        expect(page).to have_content("Payments source can't be blank")
      end
    end

    context "if payment has been made" do
      it "should proceed to the next step" do
        visit '/checkout/payment'
        choose(option: paypal_payment_method.id)
        find(:xpath, "//input[@id='payments_source_paypal_order_id']", visible: false).set SecureRandom.hex(8)
        click_button("Save and Continue")
        expect(page).to have_css(".current", text: "Confirm")
      end
    end

  end
end