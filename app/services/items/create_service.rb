# frozen_string_literal: true

module Items
  class CreateService
    def initialize(user:, params:, day_id: nil, parent_item_id: nil)
      @user = user
      @params = params
      @day_id = day_id
      @parent_item_id = parent_item_id
    end

    def call
      item = @user.items.build(@params)

      unless item.save
        return { success: false, error: item.errors.full_messages.join(", ") }
      end

      if @parent_item_id.present?
        add_to_parent_item(item)
      elsif @day_id.present?
        add_to_day(item)
      end

      { success: true, item: item }
    rescue ActiveRecord::RecordNotFound => e
      { success: false, error: e.message }
    end

    private

    def add_to_parent_item(item)
      parent_item = @user.items.find(@parent_item_id)
      parent_descendant = parent_item.descendant || Descendant.create!(
        descendable: parent_item,
        active_items: [],
        inactive_items: []
      )
      parent_descendant.add_active_item(item.id)
      parent_descendant.save!
    end

    def add_to_day(item)
      day = @user.days.find(@day_id)
      day.descendant.add_active_item(item.id)
      day.descendant.save!
    end
  end
end
