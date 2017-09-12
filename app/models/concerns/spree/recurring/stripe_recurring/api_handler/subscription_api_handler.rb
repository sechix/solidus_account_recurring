module Spree
  class Recurring < Spree::Base
    class StripeRecurring < Spree::Recurring
      module ApiHandler
        module SubscriptionApiHandler
          def subscribe(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription)
            customer = subscription.user.find_or_create_stripe_customer(subscription.card_token)
            customer.subscriptions.create(plan: subscription.plan.stripe_id)
          end

          def unsubscribe(subscription)
            raise_invalid_object_error(subscription, Spree::Subscription)
            subscription.user.api_customer.cancel_subscription
          end


          def update(subscription, plan_id)
            raise_invalid_object_error(subscription, Spree::Subscription)
            subscription.user.api_customer.update_subscription( {plan: subscription.plan.stripe_id, prorate: false} )
          end
        end
      end
    end
  end
end