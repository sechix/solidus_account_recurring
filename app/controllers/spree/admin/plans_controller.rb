module Spree
  module Admin
    class PlansController < Spree::Admin::BaseController
      before_action :load_recurring
      before_action :find_plan, :only => [:edit, :destroy, :update]

      def index
        @plans = Spree::Plan.undeleted.order('id desc')
      end

      def new
        @plan = @recurring.plans.build
      end

      def create
        @plan = @recurring.plans.build(plan_params)
        if @plan.save_and_manage_api
          flash[:notice] = 'Plan created successfully.'
          redirect_to edit_admin_recurring_plan_path(@recurring, @plan)
        else
          render :new
        end
      end

      def update
        if @plan.save_and_manage_api(plan_params(:update))
          flash[:notice] = 'Plan updated successfully.'
          redirect_to edit_admin_recurring_plan_path(@recurring, @plan)
        else
          render :edit
        end
      end

      def destroy
        if @plan.restrictive_destroy_with_api
          flash[:success] = "Plan has been deleted."
        else
          flash[:error] = "Plan could not be deleted."
        end
        render_js_for_destroy
      end

      private

      def load_recurring
        unless @recurring = Spree::Recurring.undeleted.where(id: params[:recurring_id]).first
          flash[:error] = "Recurring not found."
          redirect_to admin_recurrings_path
        end
      end

      def plan_params(action=:create)
          params.require(:plan).permit(:name, :description, :free_shipping, :free_cleaning, :trial_period_days, :interval, :currency, :amount, :active, :interval_count,:plan1,:plan2,:plan3, :special_sales, :default)
      end

      def find_plan
        unless @plan = @recurring.plans.undeleted.where(id: params[:id]).first
          flash[:error] = "Plan not found."
          redirect_to admin_recurring_plans_path(@recurring)
        end
      end
    end
  end
end
