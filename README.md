SpreeInstallments
=================

Introduction goes here.

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
Each installment capable product is identified by shipping category and can be splitted in individual shipment. For that InstallmentShippingCategory splitter is created.

We have preference setting shipping category for which individual shipment needs to be created, Which can be set with Spree::Config[:installment_shipping_category_id]. Default value is 2.

We have following new models which are used installment capability.

1. InstallmentPlan
   - belongs to product
   - belongs to shipment
   - has_many installments
2. Installment
   - belongs to installment plan

On shipment installment plan is created for that shipment and installments are calculated and added to installment plan. Every installment can be due or paid. We have takend this approach as to make recurring profile on braintree and paypal we need to create plan and from there we can set recurring payments. Authorizing card can max be valid upto 30 days. So authorizing card once and then capture payment will not work.

We have created Rescue job to process due installments. Which will look into spree_installments table for past_due installments and capture payments for them. This might change we will integrate recurring payment.


Now next step is make recurring payment and create recurring payment profile. We are working on that and that can also be ready in 3-4 upcoming days. Above implementaion might change little bit accordingly how recurring payment goes.


Thanks for patience and support.
