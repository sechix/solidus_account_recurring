module Spree
  class SubscriptionsController < StoreController
    prepend_before_action :load_object
    prepend_before_action :check_registration,
                          except: [:registration, :update_registration]



    before_action :find_active_plan, only: [:new, :create]
    before_action :find_plan, only: [:show, :destroy, :update, :new, :registration, :apply_coupon]
    before_action :find_subscription, only: [:destroy]
    before_action :authenticate_subscription, only: [:new, :create]
    before_action :payment_method, only: [:new]
    after_action :add_to_subscribers_mailchimp, only: [:create]

    def new
      @total_with_discount = @plan.amount
      if @user_subscriptions.present? or try_spree_current_user.try(:has_spree_role?, "subscriber")
        flash[:error] = Spree.t(:already_have_subscription)
        redirect_to '/account#my_plans' and return
      else
        @subscription = @plan.subscriptions.build
        if try_spree_current_user && try_spree_current_user.respond_to?(:wallet)
          @wallet_payment_sources = try_spree_current_user.wallet.wallet_payment_sources
          @default_wallet_payment_source = @wallet_payment_sources.detect(&:default) ||
              @wallet_payment_sources.first
          # TODO: How can we deprecate this instance variable?  We could try
          # wrapping it in a delegating object that produces deprecation warnings.
          @payment_sources = try_spree_current_user.wallet.wallet_payment_sources.map(&:payment_source).select { |ps| ps.is_a?(Spree::CreditCard) }
        end
      end

    end

    def payment_method
      @payment_method = Spree::PaymentMethod.find_by(type: 'Spree::PaymentMethod::StripeCreditCard', deleted_at: nil)
    end

    def create
      coupon_code = params[:coupon_code].present? ? params[:coupon_code]:nil
      use_existing_card = params[:use_existing_card].present?  ? params[:use_existing_card]: 'not'
      wallet_payment_source_id = params[:order].present?  ? params[:order][:wallet_payment_source_id]: nil
      payment_source = params[:payment_source].present?  ? params[:payment_source]: nil

          @subscription = @plan.subscriptions.build(subscription_params.merge(user_id: current_spree_user.id))
          if @subscription.subscribe(use_existing_card, payment_source, wallet_payment_source_id, coupon_code)  && @subscription.save_and_manage_api_3
              @plan_plan1 = @plan.plan1
              @plan_plan2 = @plan.plan2
              @plan_plan3 = @plan.plan3

              if current_spree_user.update_columns(available_plan1: current_spree_user.available_plan1 + @plan_plan1,
                                                   available_plan2: current_spree_user.available_plan2 + @plan_plan2,
                                                   available_plan3: current_spree_user.available_plan3 + @plan_plan3,
                                                   month_order_done: false)
                    redirect_to '/subscribersteps' , notice: Spree.t(:thanks_for_subscribing)
              else
                flash[:error] = Spree.t(:error)
                name_plan = ['/recurring/plans/',@plan.id,'/subscriptions/new'].join("");
                redirect_back_or_default(name_plan)
              end
          else
              flash[:error] = Spree.t(:error)
              name_plan = ['/recurring/plans/',@plan.id,'/subscriptions/new'].join("");
              redirect_back_or_default(name_plan)
          end
    end

    def destroy
      if @subscription.save_and_manage_api(unsubscribed_at: Time.current)

        if  current_spree_user.update_columns(available_plan1: 0, available_plan2: 0, available_plan3: 0,
                                              own_plan1: 0, own_plan2: 0, own_plan3: 0)
          current_spree_user.category_plans.destroy_all
          flash[:notice] = Spree.t(:subscription_canceled)
          redirect_to(spree.account_url)
        else
          flash[:error] = Spree.t(:error)
          redirect_to(spree.account_url)
        end
      else
        flash[:error] = Spree.t(:error)
        redirect_to(spree.account_url)
      end

    end


    def update
      if !current_spree_user.month_order_done
        flash[:error] = Spree.t(:no_change_plan_order_done)
        redirect_to(spree.account_url)
      else
        @plan = Spree::Plan.active.where(id: params[:plan_id]).first
        if @subscription = Spree::Subscription.undeleted.where(id: params[:id]).first
              # @plan_points_previous = Spree::Plan.active.where(id: @subscription.plan_id).first.points
              plan_plan1 = @plan.plan1
              plan_plan2 = @plan.plan2
              plan_plan3 = @plan.plan3

              previousplan = Spree::Plan.find_by(id: @subscription.plan_id)
              previousplan_plan1 = previousplan.plan1
              previousplan_plan2 = previousplan.plan2
              previousplan_plan3 = previousplan.plan3

              if @subscription.update(@plan.api_plan_id)
                 if @subscription.save_and_manage_api(plan_id: @plan.id)
                        if  current_spree_user.update_columns(available_plan1: current_spree_user.available_plan1 + @plan.plan1 - previousplan.plan1,
                                                              available_plan2: current_spree_user.available_plan2 + @plan.plan2 - previousplan.plan2,
                                                              available_plan3: current_spree_user.available_plan3 + @plan.plan3 - previousplan.plan3)
                            flash[:notice] = Spree.t(:subscription_change)
                            redirect_to(spree.account_url)
                        else
                            flash[:error] = Spree.t(:error)
                            redirect_to(spree.account_url)
                        end 
                 else
                  flash[:error] = Spree.t(:error)
                  redirect_to(spree.account_url)
                 end 
              else
                  flash[:error] = Spree.t(:error)
                  redirect_to(spree.account_url)
              end
           else
              flash[:error] = Spree.t(:error)
              redirect_to(spree.account_url)
          end
        end
    end
    def edit


    end
    def registration
      redirect_to new_recurring_plan_subscription_url(@plan) if spree_current_user
      @user = Spree::User.new
      @showlogin = params[:showlogin].present? ? params[:showlogin] : "register"
    end


    # Introduces a registration step whenever the +registration_step+ preference is true.
    def check_registration
      return unless registration_required?
      store_location
      redirect_to spree.subscriptions_registration_path(:plan_id => params[:plan_id])
    end

    def registration_required?
      Spree::Auth::Config[:registration_step] &&
          !already_registered?
    end

    def already_registered?
      spree_current_user
    end
    

    private


    def add_to_subscribers_mailchimp
      if params[:accept_promotions_mails]

        result = SolidusMailchimpSync::Mailchimp.request(
            :put,
            "/lists/#{ENV['LIST_ID']}/members/#{SolidusMailchimpSync::Util.subscriber_hash(spree_current_user.email)}",
            body: {
                status: "subscribed",
                email_address: spree_current_user.email
            })

      end
    end


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
      params.require(:subscription).permit(:email, :token)
    end


    def load_object


    end

    def authenticate_subscription
      if current_spree_user
          if subscription = current_spree_user.subscriptions.undeleted.first
            flash[:alert] = Spree.t(:already_subscribed)
            redirect_to '/account'
          end
      end

    end
  end
end