Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :recurrings, except: :show do
      resources :plans, except: :show
    end

    resources :subscriptions, only: :index
    resources :subscription_events, only: :index
  end

  resources :recurring_hooks, only: :none do
    post :handler, on: :collection
  end

  namespace :recurring do
    resources :plans, only: [ :index , :show ], controller: '/spree/plans' do
      resources :subscriptions, only: [:show, :create, :destroy, :new, :update, :edit ], controller: '/spree/subscriptions' do
        get :apply_coupon , on: :member
      end
    end
  end  


  namespace :recurring do
      resources :resources, only: [ :new , :create ], controller: '/spree/resources' do
         get :getcustomer , on: :collection 
      end
  end 
  get 'recurring/resources', :to => 'resources#create'

end
