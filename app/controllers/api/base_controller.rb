module Api
  class BaseController < ActionController::API
    include Apipie::DSL

    before_action :authenticate_api_token!
    before_action :authorize_api_access!

    resource_description do
      api_version "v1"
      formats [ "json" ]
      error code: 401, desc: "Authentication required — missing or invalid Bearer token"
      error code: 403, desc: "Access denied — feature not enabled for this account"
      error code: 404, desc: "Resource not found"
      error code: 422, desc: "Unprocessable entity — validation errors"
    end

    def_param_group :pagination do
      param :page, :number, desc: "Page number (default: 1)", required: false
      param :per_page, :number, desc: "Items per page (default: 25)", required: false
    end

    attr_reader :current_user

    def render_error(message, status:, errors: [])
      render json: { error: message, errors: errors }, status: status
    end

    def render_not_found
      render_error("Not found", status: :not_found)
    end

    def authorize_feature!(feature)
      return if @current_user.has_role?(feature.to_s)

      render_error("Access denied: #{feature} feature not enabled", status: :forbidden)
    end

    private

    def authenticate_api_token!
      token = extract_bearer_token
      if token.blank?
        render_error("Authentication required", status: :unauthorized)
        return
      end

      api_token = ApiToken.find_by_plain_token(token)
      if api_token.nil?
        render_error("Invalid API token", status: :unauthorized)
        return
      end

      @current_user = api_token.user
      @api_token = api_token
      api_token.touch_last_used!
    end

    def authorize_api_access!
      return if @current_user&.has_role?("api")

      render_error("API access not enabled for this account", status: :forbidden)
    end

    def extract_bearer_token
      header = request.headers["Authorization"]
      return nil unless header&.start_with?("Bearer ")

      header.split(" ", 2).last
    end
  end
end
