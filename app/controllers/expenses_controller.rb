class ExpensesController < ApplicationController
  def create
    @expense = Expense.new({ group_id: params[:group_id], **expense_params })
    unless validate_transactions.empty?
      return render json: { error: validate_transactions }, status: :unprocessable_entity
    end

    add_transactions
    if @expense.save
      render json: { expense: ExpensesBlueprint.render_as_json(@expense, view: :normal, user_id: @current_user.id) },
             status: :created
    else
      render json: { error: @expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    @expenses = Group.find(params[:group_id]).expenses
    render json: { expenses: ExpensesBlueprint.render_as_json(@expenses, view: :normal, user_id: @current_user.id) },
           status: :ok
  end

  private

  def valid_float?(str)
    !!Float(str)
  rescue StandardError
    false
  end

  def validate_transactions
    validations = %i[validate_expense validate_member_count validate_float_amounts validate_members validate_balances]
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

  def validate_member_count
    return true if (expense_params[:category] == 'multiple') || ((transaction_params[:members]&.size || 0) == 2)

    ['Only multiple expenses can have more than 2 members']
  end

  def validate_float_amounts
    begin
      transaction_params[:members]&.each do |member|
        Float(member[:owed])
      end
    rescue ArgumentError
      return ['All amounts should be valid decimals']
    end
    true
  end

  def validate_members
    return true if transaction_params[:members]&.all? do |member|
      Group.find(params[:group_id]).user_ids.include?(member[:user_id])
    end

    ['Only members in the group can take part in an expense']
  end

  def validate_balances
    return true if (transaction_params[:members]&.reduce(0.0) do |sum, member|
      sum + member[:owed].to_f
    end&.- expense_params[:amount].to_f).abs <= 1e-2

    ['All members contributions should add up to the total amount']
  end

  def add_transactions
    group_id = params[:group_id]
    from_id = expense_params[:paid_by_id]
    transaction_params[:members]&.each do |member|
      @expense.transactions.build({ group_id:, from_id:, to_id: member[:user_id],
                                    amount: member[:owed].to_f })
    end
  end

  def expense_params
    params.require(:expense).permit(:title, :amount, :paid_by_id, :category)
  end

  def transaction_params
    params.require(:expense).permit(:paid_by_id, members: %i[user_id owed])
  end
end
