class AccountingController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    render ::Views::Accounting::Index.new(user: current_user)
  end

  def customers_tab
    render ::Views::Accounting::Customers::Index.new(user: current_user)
  end

  def accounting_items_tab
    render ::Views::Accounting::AccountingItems::Index.new(user: current_user)
  end

  def settings_tab
    render ::Views::Accounting::Settings::Index.new(user: current_user)
  end
end
