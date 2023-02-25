class Transaction < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0.0, only_float: true }

  belongs_to :expense, inverse_of: :transactions
  belongs_to :group
  belongs_to :from, class_name: 'User', inverse_of: :paid_transactions
  belongs_to :to, class_name: 'User', inverse_of: :owed_transactions
end
