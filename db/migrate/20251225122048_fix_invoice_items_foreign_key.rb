class FixInvoiceItemsForeignKey < ActiveRecord::Migration[8.1]
  def up
    # Remove the incorrect foreign key pointing to items table
    # Check if it exists first to avoid errors
    if foreign_key_exists?(:invoice_items, :items)
      remove_foreign_key :invoice_items, :items
    end

    # Add the correct foreign key pointing to accounting_items table
    add_foreign_key :invoice_items, :accounting_items, column: :item_id
  end

  def down
    # Remove the correct foreign key
    if foreign_key_exists?(:invoice_items, :accounting_items, column: :item_id)
      remove_foreign_key :invoice_items, :accounting_items, column: :item_id
    end

    # Restore the incorrect foreign key (for rollback purposes)
    add_foreign_key :invoice_items, :items
  end
end
