module Spree
  class Subscription < Spree::Base
    include RoleSubscriber
    include RestrictiveDestroyer
    include ApiHandler

    acts_as_restrictive_destroyer column: :unsubscribed_at
    attr_accessor :card_token

    self.whitelisted_ransackable_attributes = %w[email subscribed_at]

    belongs_to :plan
    belongs_to :user
    has_many :events, class_name: 'Spree::SubscriptionEvent'

    validates :plan_id, :email, :user_id, presence: true
    validates :plan_id, uniqueness: { scope: [:user_id, :unsubscribed_at] }
    validates :user_id, uniqueness: { scope: :unsubscribed_at }

    before_validation :set_email, on: :create

    validate :verify_plan, on: :create

    private

    def set_email
      self.email = user.try(:email)
    end

    def verify_plan
      errors.add :plan_id, "is not active." unless plan.try(:visible?)
    end
  end
end