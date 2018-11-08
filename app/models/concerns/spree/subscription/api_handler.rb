module Spree
  class Subscription < Spree::Base
    module ApiHandler
      extend ActiveSupport::Concern

      included do
        attr_accessor :token
        before_update :unsubscribe, :if => [:unsubscribed_at_changed?, :unsubscribed_at?]
      end

      def subscribe(use_existing_card, payment_source, wallet_payment_source_id, coupon_code)
        provider.subscribe(self, use_existing_card, payment_source, wallet_payment_source_id, coupon_code)
      end

      def unsubscribe
        provider.unsubscribe(self)
      end

      def update(api_plan_id)
        provider.update(self, api_plan_id)
      end

      def changecard(use_existing_card, payment_source, wallet_payment_source_id)
        token = self.token
        provider.changecard(self, token, use_existing_card, payment_source, wallet_payment_source_id)
      end
      
      def getcustomer
        provider.getcustomer(self)
      end

      def save_and_manage_api_3(*args)
          begin
            self.subscribed_at = Time.current
            save!
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