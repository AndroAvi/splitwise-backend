class TransactionsBlueprint < Blueprinter::Base
  view :id do
    field :id, name: :transaction_id
  end

  view :normal do
    include_view :id
    association :to, name: :user, blueprint: UsersBlueprint, view: :normal
    field :amount, name: :owed
  end
  view :balance_paid do
    association :to, name: :user, blueprint: UsersBlueprint, view: :normal
    field :amount
  end
  view :balance_owed do
    association :from, name: :user, blueprint: UsersBlueprint, view: :normal
    field :amount
  end
end
