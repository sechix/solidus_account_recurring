  module Spree
  class PlansController < StoreController

    def index
      @plans = Spree::Plan.visible.order('id desc')
    end
    def show
     unless @plan = Spree::Plan.where(id: params[:id]).first
        flash[:error] = Spree.t(:plan_not_found) 
        redirect_to '/account'
      end
    end

  end
end
