module Spree
  class ResourcesController < StoreController
    prepend_before_action :load_object
    before_action :payment_method, only: [:new]
    before_action :getcustomer, only: [:getcustomer]

    def new
      @subscription = spree_current_user.subscriptions.undeleted.first 
      @plan = Spree::Plan.active.where(id: @subscription.plan_id).first   
    end

    def payment_method
      @payment_method = Spree::PaymentMethod.find_by(type: 'Spree::Gateway::StripeGateway', deleted_at: nil)
    end
    def getcustomer
      @subscription = spree_current_user.subscriptions.undeleted.first 
      @subscription.getcustomer
    end
    def create
      @subscription = spree_current_user.subscriptions.undeleted.first 
      @plan = Spree::Plan.active.where(id: @subscription.plan_id).first 
      @subscription = Subscription.create(subscription_params)
      @subscription.plan_id = @plan.id
      @subscription.user_id = spree_current_user.id
        if @subscription.changecard
          flash[:notice] = Spree.t(:subscription_card_change)
          redirect_to '/account' and return
        else
          flash[:error] = Spree.t(:error)
          redirect_to request.path and return
        end

    end

    private


    def subscription_params
      params.require(:subscription).permit(:email, :card_token, :use_existing_card, :payment_source, :wallet_payment_source_id)
    end


    def load_object
      @user ||= spree_current_user
      authorize! params[:action].to_sym, @user
    end
  end
end