class AccountingController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    render ::Views::Accounting::Index.new
  end

  def customers_tab
    render ::Views::Accounting::Customers::Index.new
  end

  def accounting_items_tab
    render ::Views::Accounting::AccountingItems::Index.new
  end

  def settings_tab
    render ::Views::Accounting::Settings::Index.new
  end
end
