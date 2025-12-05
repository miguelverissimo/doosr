class HomeController < ApplicationController
  before_action :authenticate_user!
  layout -> { Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    render Views::Home::Index
  end
end


