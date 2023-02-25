class GroupsController < ApplicationController
  def index
    @groups = @current_user.groups
    render json: GroupsBlueprint.render(@groups, view: :index)
  end

  def show
    @group = Group.find(params[:id])
    render json: { group: GroupsBlueprint.render_as_json(@group, view: :normal) },
           status: :ok
  end

  def create
    @group = Group.new(create_group_params)
    @group.user_groups.build({ user_id: @current_user.id, group_id: @group.id, owner: true })
    create_friend_groups(create_group_params[:user_ids])
    if @group.save
      render json: { group: GroupsBlueprint.render_as_json(@group, view: :normal) },
             status: :created
    else
      render json: { error: @group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def settle_up
    @group = Group.find(params[:id])
    expenses_attributes = @group.users.map do |user|
      amount = @current_user.paid_transactions.where({ group_id: @group.id, to_id: user.id })
                            .select(:amount).map(&:amount).inject(0.0, :+) - \
               @current_user.owed_transactions.where({ from_id: user.id, group_id: @group.id })
                            .select(:amount).map(&:amount).inject(0.0, :+)

      if amount.zero?
        {}
      else
        {
          category: 'individual',
          amount: amount.abs,
          group_id: params[:id],
          paid_by_id: amount.positive? ? user.id : @current_user.id,
          transactions_attributes: [
            {
              from_id: amount.positive? ? user.id : @current_user.id,
              to_id: amount.positive? ? @current_user.id : user.id,
              amount: amount.abs,
              group_id: params[:id]
            },
            {
              from_id: amount.positive? ? user.id : @current_user.id,
              to_id: amount.positive? ? user.id : @current_user.id,
              amount: 0.0,
              group_id: params[:id]
            }
          ]
        }
      end
    end.compact_blank
    @expenses = Expense.create(expenses_attributes)
    render json: { expenses: ExpensesBlueprint.render_as_json(@expenses, view: :normal, user_id: @current_user.id) },
           status: :ok
  end

  private

  def create_friend_groups(user_ids)
    ids = ((user_ids || []) << @current_user.id).sort
    ids&.each_with_index do |_, i|
      (i + 1..ids.size - 1).each do |j|
        Group.create({ category: :friend, user_ids: [ids[i], ids[j]] })
      end
    end
  end

  def create_group_params
    params.require(:group).permit(:name, user_ids: [])
  end
end
