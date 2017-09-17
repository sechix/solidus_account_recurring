module Spree
  class Recurring < Spree::Base
    class StripeRecurring < Spree::Recurring
      module ApiHandler
        module SubscriptionApiHandler
          def subscribe(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription)
            customer = subscription.user.find_or_create_stripe_customer(subscription.card_token)
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
        end
      end
    end
  end
end