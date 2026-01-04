class AddNotificationTimeToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :notification_time, :datetime
    add_index :items, :notification_time
  end
end
