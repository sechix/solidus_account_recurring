module Spree
  class RecurringHooksController < BaseController
    skip_before_action :verify_authenticity_token
    
    before_action :authenticate_webhook
    before_action :find_subscription

    respond_to :json

    def handler
      retrieve_api_event
      @subscription_event = Spree::Subscription_event.new(:event_id => @event.id, 
       :subscription_id => @subscription.id , :request_type => @event.type )
      if @subscription_event.save
        render_status_ok
      else
        render_status_failure
      end
    end

    private

    def event
      @event ||= (Rails.env.production? ? params.deep_dup : params.deep_dup[:recurring_hook])
    end
    
    def authenticate_webhook
      render_status_ok if event.blank? || (event[:livemode] != Rails.env.production?) || (!Spree::Recurring::StripeRecurring::WEBHOOKS.include?(event[:type]))
    end

    def find_subscription
      credit_card = Spree::CreditCard.find_by(gateway_customer_profile_id = event[:data][:object][:customer], default: true)
      render_status_ok unless  @subscription = Spree::User.find_by(id: credit_card.user_id).subscriptions
    end

    def retrieve_api_event
      @event = @subscription.provider.retrieve_event(event[:id])
    end

    def subscription_event_params
      if retrieve_api_event && event.data.object.customer == @subscription.user.find_or_create_stripe_customer
        { event_id: event.id, request_type: event.type, response: event.to_json }
      else
        {}
      end
    end

    def render_status_ok
      render plain: '', status: 200
    end

    def render_status_failure
      render plain: '', status: 403
    end
  end
end