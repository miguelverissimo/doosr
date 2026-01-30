module Banking
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action { authorize! :access, :banking }
  end
end
