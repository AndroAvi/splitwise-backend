class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  has_many :user_groups, dependent: :destroy
  has_many :groups, through: :user_groups

  def generate_auth_token
    JWT.encode({ id:, exp: (Time.current + (60 * 60 * 24)).to_i }, ENV['JWT_SECRET'])
  end
end
