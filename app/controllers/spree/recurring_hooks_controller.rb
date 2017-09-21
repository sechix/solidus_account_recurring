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
      render_status_ok unless  @subscription = Spree::User.find_by(stripe_customer_id: event[:data][:object][:customer]).subscriptions
    end

    def retrieve_api_event
      @event = Stripe::Event.retrieve(event[:id])
    end

    def subscription_event_params
      if retrieve_api_event && event.data.object.customer == @subscription.user.stripe_customer_id
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