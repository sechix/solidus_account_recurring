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
      @subscription = @plan.subscriptions.build(subscription_params.merge(user_id: spree_current_user.id))
      if @subscription.save_and_manage_api
          @plan_points = @plan.points

          unless spree_current_user.own_points.nil? 
            @plan_points = @plan_points - spree_current_user.own_points
          end
          if spree_current_user.update_columns(available_points: @plan_points)
            NotificationsMailer.subscription_created(@plan.name, spree_current_user, @plan_points).deliver_now
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

        if  spree_current_user.update_columns(available_points: 0)
            NotificationsMailer.subscription_deleted(@plan.name, spree_current_user, @plan_points).deliver_now 
            flash[:notice] = Spree.t(:subscription_canceled)
            redirect_to '/account' and return 
 
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
                    unless @plan_points_previous.nil?
                          @update_points = spree_current_user.available_points + @plan_points - @plan_points_previous
                          if spree_current_user.update_columns(available_points: @update_points) && @plan_points.present? && @plan_points_previous.present?
                              NotificationsMailer.subscription_updated(@event[:data][:object][:plan][:name], spree_current_user, @plan_points).deliver_now
                              flash[:notice] = Spree.t(:subscription_change)
                              redirect_to '/account' and return
                          else
                              flash[:error] = Spree.t(:error)
                              redirect_to '/account'
                          end 
                    end
                 else
                  flash[:error] = Spree.t(:error)
                  redirect_to '/account'
                 end 
              else
                  flash[:error] = Spree.t(:error)
                  redirect_to '/account'
              end
           else
              flash[:error] = Spree.t(:error)
              redirect_to '/account'
           end       
    end
    def edit
      @subscription = spree_current_user.subscriptions.undeleted.first 
      @plan = Spree::Plan.active.where(id: @subscription.plan_id).first  

    end


    private

    def find_active_plan
      unless @plan = Spree::Plan.active.where(id: params[:plan_id]).first
        flash[:error] = Spree.t(:plan_not_found)
        redirect_to '/account'
      end
    end

    def find_plan
      unless @plan = Spree::Plan.where(id: params[:plan_id]).first
        flash[:error] = Spree.t(:plan_not_found)
        redirect_to '/account'
      end
    end

    def find_subscription
      unless @subscription = @plan.subscriptions.undeleted.where(id: params[:id]).first
        flash[:error] = Spree.t(:subscription_not_found)
        redirect_to '/account'
      end
    end

    def subscription_params
      params.require(:subscription).permit(:email, :card_token)
    end


    def load_object


    end

    def authenticate_subscription
      if subscription = spree_current_user.subscriptions.undeleted.first
        flash[:alert] = Spree.t(:already_subscribed)
        redirect_to '/account'
      end
    end
  end
end