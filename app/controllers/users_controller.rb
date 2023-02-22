class UsersController < ApplicationController
  skip_before_action :authorize, only: %i[create login index]
  def index
    @users = User.all
    render json: UsersBlueprint.render(@users), status: :ok
  end

  def create
    @user = User.new(user_params)
    if @user.save
      render json: { user: UsersBlueprint.render_as_json(@user), token: @user.generate_auth_token }, status: :created
    else
      render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    @user = User.find_by(email: login_params[:email])
    if !@user
      render json: { error: 'User not found' }, status: :not_found
    elsif @user.authenticate(login_params[:password])
      render json: { token: @user.generate_auth_token }, status: :accepted
    else
      render json: { message: 'Invalid username or password' }, status: :unauthorized
    end
  end

  private

  def user_params
 	  params.require(:user).permit(:name, :email, :password)
  end

	 def login_params
    params.permit(:email, :password)
  end
end
