Spree::User.class_eval do
  has_many :subscriptions, class_name: "Spree::Subscription", foreign_key: "user_id"

  def find_or_create_stripe_customer(token=nil)
    if stripe_customer_id?
      unless api_customer.default_source.nil?
        card = api_customer.sources.create(source: subscription.card_token)
        api_customer.default_source = card.id
        api_customer.save
        return api_customer
      else
        return api_customer
      end
    end
    customer = if token
      Stripe::Customer.create(description: email, email: email, card: token)
    else
      Stripe::Customer.create(description: email, email: email)
    end
    update_column(:stripe_customer_id, customer.id)
    customer
  end

  def find_or_create_stripe_customer_2(token=nil)
    return api_customer if stripe_customer_id?
  end

  def find_stripe_customer
    return api_customer if stripe_customer_id?
  end

  def api_customer
    Stripe::Customer.retrieve(stripe_customer_id)
  end
end
