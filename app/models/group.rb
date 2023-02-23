class Group < ApplicationRecord
  enum :category, %i[regular friend], suffix: true
  validates :name, presence: true
  
  has_many :user_groups, dependent: :destroy
  has_many :users, through: :user_groups
end
