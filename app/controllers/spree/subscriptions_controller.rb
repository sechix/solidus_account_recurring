module Spree
  class SubscriptionsController < StoreController
    prepend_before_action :load_object
    before_action :find_active_plan, only: [:new, :create]
    before_action :find_plan, only: [:show, :destroy, :update]
    before_action :find_subscription, only: [:destroy]
    before_action :authenticate_subscription, only: [:new, :create]
    before_action :payment_method, only: [:new]

    def new
      @subscription = @plan.subscriptions.build  
    end

    def payment_method
      @payment_method = Spree::PaymentMethod.find_by(type: 'Spree::Gateway::StripeGateway', deleted_at: nil)
    end

    def create
      @subscription = @plan.subscriptions.build(subscription_params.merge(user_id: current_spree_user.id))
      if @subscription.save_and_manage_api
          @plan_points = @plan.points
           
          unless current_spree_user.own_points.nil? 
            @plan_points = @plan_points - current_spree_user.own_points
          end
          if current_spree_user.update_columns(available_points: @plan_points)
            redirect_to '/store/steps_subscribers' , notice: Spree.t(:thanks_for_subscribing) 
          else
            flash[:error] = Spree.t(:error)
            redirect_to '/account' and return
          end  
      else
          flash[:error] = Spree.t(:error)
          redirect_to '/account' and return
      end
    end

    def destroy
      if @subscription.save_and_manage_api(unsubscribed_at: Time.current)
        if  current_spree_user.update_columns(available_points: 0)
            redirect_to '/account', notice: Spree.t(:subscription_canceled)
        else
            flash[:error] = Spree.t(:error)
            redirect_to  '/account' and return
        end
      else
        flash[:error] = Spree.t(:error)
        redirect_to  '/account' and return
      end
   
    end

    def update

          if @subscription = Spree::Subscription.undeleted.where(id: params[:id]).first
              @plan_points_previous = Spree::Plan.active.where(id: @subscription.plan_id).first.points
              @plan_points = @plan.points
              if @subscription.update(@plan.api_plan_id)
                 if @subscription.save_and_manage_api(plan_id: @plan.id)
                        @update_points = current_spree_user.available_points + @plan_points - @plan_points_previous
                        if current_spree_user.update_columns(available_points: @update_points) && @plan_points.present? && @plan_points_previous.present?
                            flash[:notice] = Spree.t(:subscription_change)
                            redirect_to '/account' and return
                        else
                            flash[:error] = Spree.t(:error)
                            redirect_to '/account' and return
                        end 
                 else
                  flash[:error] = Spree.t(:error)
                  redirect_to '/account' and return
                 end 
              else
                  flash[:error] = Spree.t(:error)
                  redirect_to '/account' and return
              end
           else
              flash[:error] = Spree.t(:error)
              redirect_to '/account' and return
           end       
    end
    def edit
      @subscription = current_spree_user.subscriptions.undeleted.first 
      @plan = Spree::Plan.active.where(id: @subscription.plan_id).first  

    end


    private

    def find_active_plan
      unless @plan = Spree::Plan.active.where(id: params[:plan_id]).first
        flash[:error] = Spree.t(:plan_not_found)
        redirect_to '/account' and return
      end
    end

    def find_plan
      unless @plan = Spree::Plan.where(id: params[:plan_id]).first
        flash[:error] = Spree.t(:plan_not_found)
        redirect_to '/account' and return
      end
    end

    def find_subscription
      unless @subscription = @plan.subscriptions.undeleted.where(id: params[:id]).first
        flash[:error] = Spree.t(:subscription_not_found)
        redirect_to '/account' and return
      end
    end

    def subscription_params
      params.require(:subscription).permit(:email, :card_token)
    end


    def load_object


    end

    def authenticate_subscription
      if subscription = current_spree_user.subscriptions.undeleted.first
        flash[:alert] = Spree.t(:already_subscribed)
        redirect_to '/account'
      end
    end
  end
end