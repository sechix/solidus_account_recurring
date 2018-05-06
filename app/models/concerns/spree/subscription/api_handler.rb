module Spree
  class Subscription < Spree::Base
    module ApiHandler
      extend ActiveSupport::Concern

      included do
        attr_accessor :card_token
        before_update :unsubscribe, :if => [:unsubscribed_at_changed?, :unsubscribed_at?]
      end

      def subscribe(use_existing_card, payment_source, wallet_payment_source_id)
        provider.subscribe(self, use_existing_card, payment_source, wallet_payment_source_id)
        self.subscribed_at = Time.current
      end

      def unsubscribe
        provider.unsubscribe(self)
      end

      def update(api_plan_id)
        provider.update(self, api_plan_id)
      end

      def changecard
        card_token = self.card_token
        provider.changecard(self,card_token)
      end
      
      def getcustomer
        provider.getcustomer(self)
      end

      def save_and_manage_api_3(use_existing_card, payment_source, wallet_payment_source_id)
        begin
          new_record? ? save : update_attributes(*args)
          subscribe(use_existing_card, payment_source, wallet_payment_source_id)
        rescue provider.error_class, ActiveRecord::RecordNotFound => e
          logger.error "Error while subscribing: #{e.message}"
          errors.add :base, Spree.t(:problem_credit_card)
          false
        end
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