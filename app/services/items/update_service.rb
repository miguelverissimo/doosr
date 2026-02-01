# frozen_string_literal: true

module Items
  class UpdateService
    def initialize(item:, params:)
      @item = item
      @params = params
    end

    def call
      if @item.update(@params)
        { success: true, item: @item }
      else
        { success: false, error: @item.errors.full_messages.join(", ") }
      end
    end
  end
end
