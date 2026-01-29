class MakeNotificationItemOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notifications, :item_id, true
  end
end
