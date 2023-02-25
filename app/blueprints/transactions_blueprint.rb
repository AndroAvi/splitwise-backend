class TransactionsBlueprint < Blueprinter::Base
  identifier :id, name: :transaction_id
  view :normal do
    association :to, name: :user, blueprint: UsersBlueprint, view: :normal
    field :amount, name: :owed
  end
end
