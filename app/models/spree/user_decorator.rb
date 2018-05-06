Spree::User.class_eval do
  has_many :subscriptions, class_name: "Spree::Subscription", foreign_key: "user_id"

  def find_or_create_stripe_customer(token=nil)

    wallet_payment_sources = self.wallet.wallet_payment_sources
    default_wallet_payment_source = wallet_payment_sources.detect(&:default) ||
        wallet_payment_sources.first

    if default_wallet_payment_source && !default_wallet_payment_source.gateway_customer_profile_id.nil?
      credit_card = Spree::CreditCard.find_by(id: default_wallet_payment_source.payment_source_id)
      credit_card.gateway_customer_profile_id
    else
      customer = Stripe::Customer.create(description: email, email: email)
      customer
    end

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
