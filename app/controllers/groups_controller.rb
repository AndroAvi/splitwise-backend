class GroupsController < ApplicationController
  def create
    @group = Group.new(name: create_group_params[:name])
    add_self
    add_users(create_group_params[:user_ids])
    if @group.save
      render json: { group: @group }, status: :created
    else
      render json: { error: @group.errors.full_messages }, status: unprocessable_entity
    end
  end

  def add_user
    @group = Group.find(add_user_params[:group_id])
    unless @group.user_groups.find_by(user_id: @current_user.id, owner: true)
      return render json: { error: 'Logged-in user is not the group owner' }, status: :forbidden
    end

    add_users(add_user_params[:user_ids])
    if @group.save
      render json: { group: @group }, status: :ok
    else
      render json: { error: @group.errors.full_messages }, status: unprocessable_entity
    end
  end

  private

  def add_self
    @group.user_groups.build({ user_id: @current_user.id, group_id: @group.id, owner: true })
  end

  def add_users(user_ids)
    user_ids&.each do |user_id|
      @group.user_groups.build({ user_id:, group_id: @group.id })
    end
  end

  def add_user_params
    params.permit(:group_id, user_ids: [])
  end

  def create_group_params
    params.require(:group).permit(:name, user_ids: [])
  end
end
