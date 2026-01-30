module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action { authorize! :access, :admin }
  end
end
