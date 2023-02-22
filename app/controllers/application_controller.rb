class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, ActionController::UnpermittedParameters, with: :bad_body
  before_action :authorize

  private

  def auth_header
    request.headers['Authorization']
  end

  def authorize
    return render json: { error: 'No token provided.' }, status: :unauthorized unless auth_header

    begin
      decoded = JWT.decode(auth_header.split(' ')[1], ENV['JWT_SECRET'], true, algorithm: 'HS256')
      @current_user = User.find(decoded[0]['id'])
    rescue JWT::ExpiredSignature
      render json: { error: 'Token expired' }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end

  def not_found
    render json: { error: 'Record Not found' }, status: :not_found
  end

  def bad_body
    render json: { error: 'Invalid body' }, status: :bad_request
  end
end
