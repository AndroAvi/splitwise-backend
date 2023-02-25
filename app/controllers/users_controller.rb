class UsersController < ApplicationController
  skip_before_action :authorize, only: %i[create login index]
  def index
    @users = User.all
    render json: UsersBlueprint.render(@users, view: :normal), status: :ok
  end

  def create
    @user = User.new(user_params)
    if @user.save
      render json: { user: UsersBlueprint.render_as_json(@user, view: :normal), token: @user.generate_auth_token },
             status: :created
    else
      render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    @user = User.find_by(email: login_params[:email])
    if !@user
      render json: { error: ['User not found'] }, status: :not_found
    elsif @user.authenticate(login_params[:password])
      render json: { token: @user.generate_auth_token }, status: :accepted
    else
      render json: { error: ['Invalid username or password'] }, status: :unauthorized
    end
  end

  def search
    @users = case search_params[:by]
             when 'name' then User.where('name ~ ?', search_params[:value])
             when 'email' then User.where(search_params[:value])
             else []
             end
    if @users
      render json: { user: UsersBlueprint.render_as_json(@users, view: :normal) }, status: :ok
    else
      render json: { error: ['No user found'] }, status: :not_found
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end

  def login_params
    params.permit(:email, :password)
  end

  def search_params
    params.permit(:by, :value)
  end
end
