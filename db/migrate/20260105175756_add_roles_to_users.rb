class AddRolesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :roles, :string, array: true, default: []
    add_column :users, :access_confirmed, :boolean, default: false, null: false
  end
end
