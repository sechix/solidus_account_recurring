module Spree
  module Admin
    class SubscriptionsController < Spree::Admin::BaseController
      include RansackDateSearch
      ransack_date_searchable date_col: 'subscribed_at'

      def index
        params[:q] = {} unless params[:q]

        if params[:q][:returndate_gteq].blank?
          params[:q][:returndate_gteq] = Date.today + 1.days
        else
          params[:q][:returndate_gteq] = params[:q][:returndate_gteq].to_date
        end

        if params[:q][:returndate_lteq].blank?
          params[:q][:returndate_lteq] = Date.today.end_of_month
        else
          params[:q][:returndate_lteq] = params[:q][:returndate_lteq].to_date
        end



        if params[:q]
          @search = Spree::Subscription.ransack(params[:q])
        else
          @search = Spree::Subscription.undeleted
        end
        @subscriptions = @search.result.includes(plan: :recurring).references(plan: :recurring).page(params[:page]).per(15)
        respond_with(@subscriptions)
      end
    end
  end
end
