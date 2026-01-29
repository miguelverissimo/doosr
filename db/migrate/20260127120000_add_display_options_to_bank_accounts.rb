# frozen_string_literal: true

class AddDisplayOptionsToBankAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :bank_accounts, :bg_color, :string, default: "#3B82F6"
    add_column :bank_accounts, :fg_color, :string, default: "#FFFFFF"
    add_column :bank_accounts, :letter, :string, limit: 2
  end
end
