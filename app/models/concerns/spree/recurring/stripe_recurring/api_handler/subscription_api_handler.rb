 module Spree
  class Recurring < Spree::Base
    class StripeRecurring < Spree::Recurring
      module ApiHandler
        module SubscriptionApiHandler
          def subscribe(subscription, use_existing_card, payment_source, wallet_payment_source_id)
            raise_invalid_object_error(subscription, Spree::Subscription)

            # Find or Create the customer
            customer = subscription.user.find_or_create_stripe_customer(subscription.token)
            if use_existing_card == 'yes'
              wallet_payment_source = subscription.user.wallet.find(wallet_payment_source_id)
              credit_card = Spree::CreditCard.find_by(id: wallet_payment_source.payment_source_id)
              customer.default_source = credit_card.gateway_payment_profile_id
              customer.save
            else
              card = customer.sources.create(source: subscription.token)
              customer.default_source = card.id
              customer.save

              payment_source_id = payment_source.keys[0]
              payment_source_name = payment_source.values[0][:name]
              # Create credit card
              if card
                method = Spree::PaymentMethod.find_by(type: 'Spree::Gateway::StripeGateway', deleted_at: nil)
                credit_card = Spree::CreditCard.new(month: card.exp_month, year: card.exp_year, cc_type: card.brand.downcase,
                                                    last_digits: card.last4, gateway_customer_profile_id: customer.id, gateway_payment_profile_id: card.id,
                                                    name: payment_source_name, user_id: subscription.user.id, payment_method_id: payment_source_id)
                credit_card.save!

                # Create wallet record
                wallet_payment_source =  subscription.user.wallet.add(credit_card)
                subscription.user.wallet.default_wallet_payment_source = wallet_payment_source
              end
            end


            # Create the subscription
            customer.subscriptions.create(plan: subscription.plan.api_plan_id)
          end

          def unsubscribe(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription)
            subscription.user.api_customer.cancel_subscription
          end


          def update(subscription, api_plan_id)
            raise_invalid_object_error(subscription, Spree::Subscription)
            subscription.user.api_customer.update_subscription(plan: api_plan_id, prorate: false )
          end
          def changecard(subscription, token, use_existing_card, payment_source, wallet_payment_source_id)
            raise_invalid_object_error(subscription, Spree::Subscription)

            # Find or Create the customer
            customer = subscription.user.find_or_create_stripe_customer(subscription.token)
            if use_existing_card == 'yes'
              wallet_payment_source = subscription.user.wallet.find(wallet_payment_source_id)
              credit_card = Spree::CreditCard.find_by(id: wallet_payment_source.payment_source_id)
              customer.default_source = credit_card.gateway_payment_profile_id
              customer.save
            else
              card = customer.sources.create(source: subscription.token)
              customer.default_source = card.id
              customer.save

              payment_source_id = payment_source.keys[0]
              payment_source_name = payment_source.values[0][:name]
              # Create credit card
              if card
                method = Spree::PaymentMethod.find_by(type: 'Spree::Gateway::StripeGateway', deleted_at: nil)
                credit_card = Spree::CreditCard.new(month: card.exp_month, year: card.exp_year, cc_type: card.brand.downcase,
                                                    last_digits: card.last4, gateway_customer_profile_id: customer.id, gateway_payment_profile_id: card.id,
                                                    name: payment_source_name, user_id: subscription.user.id, payment_method_id: payment_source_id)
                credit_card.save!

                # Create wallet record
                wallet_payment_source =  subscription.user.wallet.add(credit_card)
                subscription.user.wallet.default_wallet_payment_source = wallet_payment_source
              end
            end

          end
          def getcustomer(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription) 
            customer = subscription.user.find_or_create_stripe_customer
            @card = customer.default_source;
          end

        end
      end
    end
  end
end