class AddCustomerReferenceToInvoice < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :customer_reference, :string
  end
end
