class Group < ApplicationRecord
  enum :category, %i[regular friend], suffix: true
  validates :name, presence: true, if: -> { category == 'regular' }

  has_many :user_groups, dependent: :destroy
  has_many :users, through: :user_groups
  has_many :expenses, dependent: :destroy, inverse_of: :group
end
