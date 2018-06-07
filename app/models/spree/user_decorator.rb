Spree::User.class_eval do
  has_many :subscriptions, class_name: "Spree::Subscription", foreign_key: "user_id"

  def find_or_create_stripe_customer(token=nil)

    if !self.stripe_customer_id.nil?
      customer = Stripe::Customer.retrieve(self.stripe_customer_id)
      return customer
    else
      customer = Stripe::Customer.create(description: email, email: email)
      self.update_columns(stripe_customer_id: customer.id)
      return customer
    end

  end


  def update_existing_stripe_customer(customer_id)
    self.update_columns(stripe_customer_id: customer_id)
    customer = Stripe::Customer.retrieve(customer_id)
    return customer
  end

  def find_stripe_customer
    return api_customer if stripe_customer_id?
  end

  def api_customer
    Stripe::Customer.retrieve(stripe_customer_id)
  end

end
