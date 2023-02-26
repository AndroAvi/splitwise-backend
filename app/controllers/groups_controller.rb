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
    @group = Group.new(group_params)
    @group.user_groups.build({ user_id: @current_user.id, group_id: @group.id, owner: true })
    create_friend_groups(group_params[:user_ids])
    if @group.save
      render json: { group: GroupsBlueprint.render_as_json(@group, view: :index) },
             status: :created
    else
      render json: { error: @group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @group = Group.find(params[:id])
    @group.update(update_params)
    create_friend_groups(group_params[:user_ids])
    render json: { group: GroupsBlueprint.render_as_json(@group, view: :index) }, status: :ok
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
        next if friend_group_exists?(ids[i], ids[j])

        Group.create({ category: :friend, user_ids: [ids[i], ids[j]] })
      end
    end
  end

  def friend_group_exists?(id1, id2)
    res = (UserGroup.joins("INNER JOIN groups g ON g.id = user_groups.group_id AND g.category=1 INNER JOIN user_groups ug1 ON ug1.group_id = user_groups.group_id AND ug1.user_id = #{id1} AND user_groups.user_id = #{id2}")
       &.size || 0)
    !res.zero?
  end

  def group_params
    params.require(:group).permit(:name, :simplify, user_ids: [])
  end

  def update_params
    {
      name: group_params[:name] || @group.name,
      simplify: group_params[:simplify] || @group.simplify,
      user_ids: @group.user_ids | (group_params[:user_ids] || [])
    }
  end
end
