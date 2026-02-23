class AddScopesToApiTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :api_tokens, :scopes, :string, array: true, default: [], null: false
  end
end
