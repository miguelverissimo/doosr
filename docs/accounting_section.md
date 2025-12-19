# Accounting section

- shows interface with 6 tabs:
  - invoices (default)
  - receipts
  - clients
  - items
  - automations
  - settings

- invoices:
  - shows a list of invoices with a rolling window of 3 months
  - has controls to show all invoices, search by client name, invoice number, or date
  - has a button to create a new invoice
  - each invoice "row" shows:
    - invoice number
    - client name
    - invoice date
    - invoice amount
    - invoice status
    - invoice actions (view, preview)

  - invoice detail:
    - shows the invoice details
    - shows the invoice items
    - shows the invoice total
    - shows the invoice status
    - allows adding an associated receipt
    - allows editing the invoice (if not marked as "paid". And with confirmation if the invoice is in the "sent" state)
    - allows previewing the invoice (special view for printing)
  
  - invoice fields:
    - invoice number (auto-generated sequence number, reset to 1 when the year changes)
    - client (select from a list of clients, required)
    - client order reference
    - invoice issue date (required)
    - due date 
    - payment terms
    - payment method
    - currency
    - exchange rate
    - collection of ItemRows
    - discount rate
    - pay by date
    - invoice total (required)
    - invoice status (draft, sent, paid) (required)
    - tax summary (json)
    - services total
    - goods total
    - tools total
    - equipment total
    - discounts total
    - tax total
    - advancements total
    - rounding total
    - grand total
    - payment details (select from a list of payment details)

- ItemRow (internal, exposed in invoice interface)
  - model that will link an item to an invoice
  - fields:
    - item (required, picked from list)
    - invoice (the invoice being created/edited)
    - placeholder replacements (json)
    - quantity
    - applied discount rate
    - applied discount value
    - applied tax rate
    - applied tax value
    - total

- receipts:
  - shows a list of receipts with a rolling window of 3 months
  - has controls to show all receipts, search by client name, receipt number, invoice number,or date
  - has a button to create a new receipt
  - each receipt "row" shows:
    - invoice number
    - receipt reference
    - client name
    - receipt date
    - receipt amount
  
  - receipt detail:
    - shows the receipt details
  
  - receipt fields:
    - invoice (select from a list of invoices, required)
    - receipt reference (required)
    - list of items and quantities (required)
    - tax rate (required)

- clients:
  - shows a list of clients
  - has controls to show all clients, search by client name, or email
  - has a button to create a new client
  - each client "row" shows:
    - client name
    - client number (the id)
    - client email
    - client phone
    - client address
    - client city
    - client state
    - number of invoices
  
  - client detail:
    - shows the client details
    - shows the client invoices
    - shows the client receipts
    - shows the client total
    - allows adding an associated invoice
    - allows editing the client

  - client fields:
    - client name (required)
    - client email (required)
    - client phone
    - client full address (required)
    - client country (required)
    - client currency (required)
    - client notes
    - client tax setting

- TaxSetting (available in settings menu)
  stores a tax setting to be applied to the client
  - fields:
    - tax exemption (boolean)
    - tax rate modifier
    - tax exemption motive

- items:
  - shows a list of items
  - has controls to show all items, search by item name, or description
  - has a button to create a new item
  - fields:
    - item reference
    - item name
    - item unit
    - item default discount
    - item usage (invoice, receipt, both)
    - item type (service, product, goods)
    - item description
    - item unit price
    - item status (active, inactive)
    - tax bracket
    - convert currency (boolean)