class AddTokenEncryptedToApiTokens < ActiveRecord::Migration[8.1]
  def change
    add_column :api_tokens, :token_encrypted, :text
  end
end

