SpreeInstallments
=================

This extension allows Spree to handle installment capable variants. You can create installment capable variant by creating OptionType and OptionValues and assigning that to variant. 


By default this extension will look for ```is-installment``` option_type. For that it assumes to have two option_values ```yes``` for installment capable and ```no``` for not installment capable. 

You can create OptionType and OptionValues with other name also. And than configure to use that in extension by setting below preference. 

```ruby
Spree::Config[:installment_option_type_name] = 'your-option-type-name'
```
```ruby
Spree::Config[:installment_option_value_name] = 'your-option-value-name-to-determine-installment-capability'
```

You can also configure installment period and installment period span by setting below config variables.

```ruby
Spree::Config[:installment_period] = 3
```
```ruby
Spree::Config[:installment_period_span] = 30
```

Installation
------------

Add spree_installments to your Gemfile:

```ruby
gem 'spree_installments'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_installments:install
```

Implementation Details
----------------------
Each installment capable variant is identified by option_type specified in Spree::Config[:installment_option_type_name] and will be splitted in individual shipments. ```InstallmentOptionTypeSplitter``` splitter is responsible for splitting them into individual shipments.

While checkout if order has installment capable shipments than max of all shipments will be determined and that amount will be authorized. Otherwise normal checkout flow will happen authorizing order total.

On shipment.ship! (or ship via admin panel) if shipment being shipped is installment capable than installments will be calculated and installment plan will be created for shipment. All calculates installments will be created for that installment plan. And first installment will be captured. Otherwise shipment total will be processed in normal spree way.

Key Points:
-----------

1.  The way we authorizing a payment (by determining max of shipment amount) there might be scenario were shipment being shipped is not authorized. So in that case it might occur to  capture partial payment. But braintree doesnt support partial payment for authorized card. So to combat that scenario we have assigned a authorized payment to shipments. So when shipment is shipped and if it has authorized payment than that will be captured, otherwise new payment will be created and will be captured using card tokenization.

2. For reference transation in Paypal billing agreement need to be created. So we have added billing_type and billing_agreement_description columns to order. So for installment capable order this two fields must be set to make paypal working for installments. 

   billing_type must be set to below value:

   ```ruby
   order.billing_type = "MerchantInitiatedBilling"
   ```
   
   Description can be set to any value:
   
   ```ruby
   order.billing_agreement_description = "DragonDoor EZ Pay option"
   ```

   Use below branch for paypal express checkout. This branch is for 2-4-stable for our project.
   
   ```ruby
   gem 'spree_paypal_express', github: 'kunalchaudhari/better_spree_paypal_express', branch: 'authorize_and_capture'
   ````
   
   
Reports
-------
1. You can see all the payment status under /admin/orders/ORDERNUMBER/payments
2. All installments also have state. So you can determing if it is due or paid or failed.


Models
------
We have following new models which are used installment capability.

1. InstallmentPlan
   - belongs to product
   - belongs to variant
   - belongs to shipment
   - has_many installments

2. Installment
   - belongs to installment plan


Rescue Job
-----------
We have created Rescue job to process due installments. Which will look into spree_installments table for past_due installments and capture payments for them. 


Testing
--------

```shell
bundle exec rake test_app
bundle exec rspec spec
```
