module Spree
  class Recurring < Spree::Base
    class StripeRecurring < Spree::Recurring
      module ApiHandler
        module SubscriptionApiHandler
          def subscribe(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription)
              if subscription.user.stripe_customer_id.nil?
                customer = subscription.user.find_or_create_stripe_customer(subscription.card_token)

              else
                customer = subscription.user.find_or_create_stripe_customer(subscription.card_token)
                card = customer.sources.create(source: subscription.card_token)               
                customer.default_source = card.id
                customer.save
              end
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
          def changecard(subscription, card_token)
            raise_invalid_object_error(subscription, Spree::Subscription) 
            customer = Stripe::Customer.retrieve(subscription.user.stripe_customer_id)
            card = customer.sources.create(source: card_token)
            customer.default_source = card.id
            customer.save
          end
          def getcustomer(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription) 
            customer = Stripe::Customer.retrieve(subscription.user.stripe_customer_id)
            @card = customer.default_source;
          end

        end
      end
    end
  end
end