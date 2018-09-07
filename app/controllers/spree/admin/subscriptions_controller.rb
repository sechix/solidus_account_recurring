module Spree
  module Admin
    class SubscriptionsController < Spree::Admin::BaseController
      include RansackDateSearch
      ransack_date_searchable date_col: 'subscribed_at'
      ransack_date_searchable date_col: 'deleted_at'

      def index
        params[:q] = {} unless params[:q]

        if params[:q][:subscribed_at_gt].blank?
          params[:q][:subscribed_at_gt] = Date.today.beginning_of_year
        else
          params[:q][:subscribed_at_gt] = params[:q][:subscribed_at_gt].to_date
        end

        if params[:q][:subscribed_at_lt].blank?
          params[:q][:subscribed_at_lt] = Date.today.end_of_month
        else
          params[:q][:subscribed_at_lt] = params[:q][:subscribed_at_lt].to_date
        end


        @search = Spree::Subscription.ransack(params[:q])
        @subscriptions = @search.result.includes(plan: :recurring).references(plan: :recurring).page(params[:page]).per(15)
        respond_with(@subscriptions)
      end
    end
  end
end
