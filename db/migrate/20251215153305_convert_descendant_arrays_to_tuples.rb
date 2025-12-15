# frozen_string_literal: true

class ConvertDescendantArraysToTuples < ActiveRecord::Migration[8.1]
  def up
    say "Converting descendant arrays from [1, 2, 3] to [{\"Item\" => 1}, {\"Item\" => 2}, {\"Item\" => 3}]"

    Descendant.find_each do |descendant|
      # Convert active_items
      if descendant.active_items.present? && descendant.active_items.first.is_a?(Integer)
        new_active_items = descendant.active_items.map { |id| { "Item" => id } }
        descendant.update_column(:active_items, new_active_items)
      end

      # Convert inactive_items
      if descendant.inactive_items.present? && descendant.inactive_items.first.is_a?(Integer)
        new_inactive_items = descendant.inactive_items.map { |id| { "Item" => id } }
        descendant.update_column(:inactive_items, new_inactive_items)
      end
    end

    say "Converted #{Descendant.count} descendant records", true
  end

  def down
    say "Converting descendant arrays back from [{\"Item\" => 1}] to [1, 2, 3]"

    Descendant.find_each do |descendant|
      # Convert active_items back to integers
      if descendant.active_items.present? && descendant.active_items.first.is_a?(Hash)
        new_active_items = descendant.active_items.map { |tuple| tuple["Item"] }
        descendant.update_column(:active_items, new_active_items)
      end

      # Convert inactive_items back to integers
      if descendant.inactive_items.present? && descendant.inactive_items.first.is_a?(Hash)
        new_inactive_items = descendant.inactive_items.map { |tuple| tuple["Item"] }
        descendant.update_column(:inactive_items, new_inactive_items)
      end
    end

    say "Reverted #{Descendant.count} descendant records", true
  end
end
