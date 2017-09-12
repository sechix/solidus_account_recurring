module Spree
  class Recurring < Spree::Base
    class StripeRecurring < Spree::Recurring
      module ApiHandler 
        module PlanApiHandler
          def create_plan(plan)
            raise_invalid_object_error(plan, Spree::Plan)
            Stripe::Plan.create(
              amount: stripe_amount(plan.amount),
              interval: plan.interval,
              interval_count: plan.interval_count,
              name: plan.name,
              currency: plan.currency,
              id: plan.stripe_id,
              trial_period_days: plan.trial_period_days,
            )
          end

          def delete_plan(plan)
            raise_invalid_object_error(plan, Spree::Plan)
            stripe_plan = retrieve_stripe(plan)
            stripe_plan.delete
          end

          def update_plan(plan)
            raise_invalid_object_error(plan, Spree::Plan)
            stripe_plan = retrieve_stripe(plan)
            stripe_plan.name = plan.name
            stripe_plan.amount = stripe_amount(plan.amount)
            stripe_plan.currency = plan.currency
            stripe_plan.trial_period_days = plan.trial_period_days
            stripe_plan.save
          end

          def set_stripe_id(plan)
            plan.stripe_id = "KS-Plan-#{Time.current.to_i}"
          end

          private

          def retrieve_stripe(plan)
            Stripe::Plan.retrieve(plan.stripe_id)
          end

          def stripe_amount(amount)
            (amount * 100).to_i
          end
        end
      end
    end
  end
end