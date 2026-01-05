class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    render ::Views::Admin::Dashboard::Index.new
  end
end
