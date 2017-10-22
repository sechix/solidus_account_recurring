  module Spree
  class PlansController < StoreController
    before_action :load_user_subscriptions

    def index
      @plans = Spree::Plan.visible.order('id desc')
    end
    def show
     unless @plan = Spree::Plan.where(id: params[:id]).first
        flash[:error] = Spree.t(:plan_not_found) 
        redirect_to '/account'
      end
    end
    
    private
      def load_user_subscriptions
        if current_spree_user
          @user_subscriptions = spree_current_user.subscriptions.undeleted.all.to_a
        else
          @user_subscriptions = []
        end
      end
  end
end
