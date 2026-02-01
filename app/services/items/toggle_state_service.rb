# frozen_string_literal: true

module Items
  class ToggleStateService
    def initialize(item:, new_state:)
      @item = item
      @new_state = new_state
    end

    def call
      case @new_state
      when "done"
        @item.set_done!
      when "dropped"
        @item.set_dropped!
      when "todo"
        if @item.section?
          @item.set_section_todo!
        else
          @item.set_todo!
        end
      else
        return { success: false, error: "Invalid state: #{@new_state}" }
      end

      { success: true, item: @item.reload }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end
end
