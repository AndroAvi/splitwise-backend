class ExpensesBlueprint < Blueprinter::Base
  identifier :id, name: :expense_id
  view :normal do
    fields :title, :amount, :group_id, :created_at, :updated_at
    field :category, name: :type
    association :user, name: :paid_by, blueprint: UsersBlueprint, view: :normal
    association :transactions, name: :members, blueprint: TransactionsBlueprint, view: :normal
    field :balance do |expense, options|
      amount_owed = expense.transactions.find_by({ to_id: options[:user_id] })&.amount
      if amount_owed.nil?
        'not involved'
      elsif options[:user_id] == expense[:paid_by_id]
        expense[:amount] - amount_owed
      else
        amount_owed * -1.0
      end
    end
  end
end
