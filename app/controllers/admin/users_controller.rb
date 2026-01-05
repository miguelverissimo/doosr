class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :toggle_access, :update_roles ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @users = User.order(created_at: :desc)
    render ::Views::Admin::Users::Index.new(users: @users)
  end

  def toggle_access
    @user.update!(access_confirmed: !@user.access_confirmed)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "user_#{@user.id}",
            ::Views::Admin::Users::UserRow.new(user: @user)
          ),
          turbo_stream.append("body", "<script>window.toast && window.toast('User access updated', { type: 'success' })</script>")
        ]
      end
    end
  end

  def update_roles
    roles = params[:roles].presence || []
    @user.update!(roles: roles)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "user_#{@user.id}",
            ::Views::Admin::Users::UserRow.new(user: @user)
          ),
          turbo_stream.append("body", "<script>window.toast && window.toast('Roles updated', { type: 'success' })</script>")
        ]
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
