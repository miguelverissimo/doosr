class Admin::DashboardController < Admin::BaseController
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    render ::Views::Admin::Dashboard::Index.new
  end
end
