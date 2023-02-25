class GroupsController < ApplicationController
  def index
    @groups = @current_user.groups
    render json: GroupsBlueprint.render(@groups, view: :index)
  end

  def create
    @group = Group.new(create_group_params)
    @group.user_groups.build({ user_id: @current_user.id, group_id: @group.id, owner: true })
    create_friend_groups(create_group_params[:user_ids])
    if @group.save
      render json: { group: GroupsBlueprint.render_as_json(@group, view: :normal) }, status: :created
    else
      render json: { error: @group.errors.full_messages }, status: unprocessable_entity
    end
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
