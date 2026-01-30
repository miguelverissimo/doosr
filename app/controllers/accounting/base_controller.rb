module Accounting
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action { authorize! :access, :accounting }
  end
end
