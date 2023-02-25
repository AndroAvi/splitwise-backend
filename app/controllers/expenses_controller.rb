class ExpensesController < ApplicationController
  def create
    @expense = Expense.new(expense_params)
    unless validate_transactions.empty?
      return render json: { error: validate_transactions },
                    status: :unprocessable_entity
    end

    add_transactions
    if @expense.save
      render json: { expense: @expense }, status: :created
    else
      render json: { error: @expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def validate_transactions
    validations = %i[validate_expense validate_friend_group validate_member_count validate_members validate_balances]
    errors = []
    validations.each do |validation|
      res = send(validation)
      errors += res if res != true
    end
    errors
  end

  def validate_expense
    return true if @expense.valid?

    @expense.errors.full_messages
  end

  def validate_friend_group
    return true if (expense_params[:category] == 'multiple') || ((expense_params[:paid_by_id] || 0) == @current_user.id)

    ['A user cannot record payments between 2 different users']
  end

  def validate_member_count
    return true if (expense_params[:category] == 'multiple') || ((transaction_params[:members]&.size || 0) == 2)

    ['Only multiple expenses can have more than 2 members']
  end

  def validate_members
    errors = []
    errors << 'All amounts should be in decimal format' unless transaction_params[:members]&.all? do |member|
      (member[:owed].is_a? Float)
    end
    errors << 'Only members in the group can take part in an expense' unless transaction_params[:members]&.all? do |member|
      Group.find(transaction_params[:group_id]).user_ids.include?(member[:user_id])
    end
    errors
  end

  def validate_balances
    return true if (transaction_params[:members]&.reduce(0.0) do |sum, member|
      sum + member[:owed]
    end&.- expense_params[:amount]).abs <= 1e-2

    ['All members contributions should add up to the total amount']
  end

  def add_transactions
    group_id = transaction_params[:group_id]
    from_id = expense_params[:paid_by_id]
    transaction_params[:members]&.each do |member|
      unless from_id == member[:user_id]
        @expense.transactions.build({ group_id:, from_id:, to_id: member[:user_id],
                                      amount: member[:owed] })
      end
    end
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :group_id, :paid_by_id, :category)
  end

  def transaction_params
    params.require(:expense).permit(:group_id, :paid_by_id, members: %i[user_id owed])
  end
end
