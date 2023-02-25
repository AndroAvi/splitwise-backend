class Expense < ApplicationRecord
  enum :category, %i[individual multiple special], suffix: true
  validates :amount, presence: true, numericality: { greater_than: 0.0, only_float: true }
  validates :category, presence: true
  validates :title, presence: { if: -> { category == 'multiple' } }
  after_initialize :set_title

  belongs_to :user, foreign_key: 'paid_by_id', inverse_of: :expenses
  belongs_to :group, inverse_of: :expenses
  has_many :transactions, inverse_of: :expense, dependent: :destroy
  def set_title
    self.title = 'Payment' unless category == 'multiple'
  end
end
