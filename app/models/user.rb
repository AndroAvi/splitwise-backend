class User < ApplicationRecord
  has_secure_password
  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  has_many :user_groups, dependent: :destroy
  has_many :groups, through: :user_groups
  has_many :expenses, foreign_key: 'paid_by_id', dependent: :destroy, inverse_of: :user
  has_many :paid_transactions, class_name: 'Transaction', foreign_key: 'from_id', inverse_of: :from, dependent: :destroy
  has_many :owed_transactions, class_name: 'Transaction', foreign_key: 'to_id', inverse_of: :to, dependent: :destroy

  def generate_auth_token
    JWT.encode({ id:, exp: (Time.current + (60 * 60 * 24)).to_i }, ENV['JWT_SECRET'])
  end
end
