module Spree
  class Subscription < Spree::Base
    module ApiHandler
      extend ActiveSupport::Concern

      included do
        attr_accessor :card_token
        before_create :subscribe
        before_update :unsubscribe, :if => [:unsubscribed_at_changed?, :unsubscribed_at?]

      end

      def subscribe
        provider.subscribe(self)
        self.subscribed_at = Time.current
      end

      def unsubscribe
        provider.unsubscribe(self)
      end

      def update(api_plan_id)
        provider.update(self, api_plan_id)
      end

      def save_and_manage_api(*args)
        begin
          new_record? ? save : update_attributes(*args)
        rescue provider.error_class, ActiveRecord::RecordNotFound => e
          logger.error "Error while subscribing: #{e.message}"
          errors.add :base, Spree.t(:problem_credit_card)
          false
        end
      end

      def provider
        plan.try(:recurring).present? ? plan.recurring : (raise ActiveRecord::RecordNotFound.new("Provider not found."))
      end
    end
  end
end