require "application_system_test_case"

class AccountingViewsTest < ApplicationSystemTestCase
  def setup
    @user = AccountingTestData.build_accounting_user_with_basic_invoicing
  end

  test "accounting index page renders successfully" do
    sign_in(@user)

    visit accounting_index_path

    # Main heading
    assert_text "Invoicing", wait: 5

    # Tab navigation
    assert_selector "button", text: "Invoices"
    assert_selector "button", text: "Templates"
    assert_selector "button", text: "Receipts"
    assert_selector "button", text: "Customers"
    assert_selector "button", text: "Items"
    assert_selector "button", text: "Settings"
  end

  test "invoices tab renders with filters and action buttons" do
    sign_in(@user)
    visit accounting_index_path

    # Wait for invoices content to load
    assert_text "Invoices", wait: 5

    # Filter badges
    assert_selector "#filter_unpaid", text: "Unpaid"
    assert_selector "#filter_paid", text: "Paid"
    assert_selector "#filter_all", text: "All"

    # Action buttons
    assert_selector "a", text: "From Template"
    assert_selector "a", text: "Add Invoice"
  end

  test "invoice templates tab renders and loads content" do
    sign_in(@user)
    visit accounting_index_path

    # Click Templates tab
    click_button "Templates"

    # Wait for tab content to appear
    assert_text "Invoice Templates", wait: 20

    # Should show either templates or empty state (wait for loading to finish)
    assert_no_text "Loading invoice templates...", wait: 15
  end

  test "receipts tab renders and loads content" do
    sign_in(@user)
    visit accounting_index_path

    # Click Receipts tab
    click_button "Receipts"

    # Wait for lazy loading to complete
    assert_text "Receipts", wait: 20

    # Should show either receipts or empty state
    assert_no_text "Loading receipts...", wait: 15
  end

  test "customers tab renders and loads content" do
    sign_in(@user)
    visit accounting_index_path

    # Click Customers tab
    click_button "Customers"

    # Wait for lazy loading to complete
    assert_text "Customers", wait: 20

    # Should show either customers or empty state
    assert_no_text "Loading customers...", wait: 15
  end

  test "accounting items tab renders and loads content" do
    sign_in(@user)
    visit accounting_index_path

    # Click Items tab
    click_button "Items"

    # Wait for lazy loading to complete
    assert_text "Accounting Items", wait: 20

    # Should show either items or empty state
    assert_no_text "Loading accounting items...", wait: 15
  end

  test "settings tab renders all settings sections" do
    sign_in(@user)
    visit accounting_index_path

    # Click Settings tab
    click_button "Settings"

    # Wait for settings content to load
    assert_text "Settings", wait: 20

    # All settings sections should be present
    assert_text "Tax Brackets", wait: 5
    assert_text "Your Addresses", wait: 5
    assert_text "Your Logos", wait: 5
    assert_text "Your Bank Infos", wait: 5

    # Wait for lazy loading to complete for all sections
    assert_no_text "Loading tax brackets...", wait: 15
    assert_no_text "Loading addresses...", wait: 5
    assert_no_text "Loading logos...", wait: 5
    assert_no_text "Loading bank infos...", wait: 5
  end

  test "all tabs can be navigated between without errors" do
    sign_in(@user)
    visit accounting_index_path

    # Start on Invoices tab
    assert_text "Invoices", wait: 5

    # Navigate through all tabs
    click_button "Templates"
    assert_text "Invoice Templates", wait: 20
    assert_no_text "Loading invoice templates...", wait: 15

    click_button "Receipts"
    assert_text "Receipts", wait: 20
    assert_no_text "Loading receipts...", wait: 15

    click_button "Customers"
    assert_text "Customers", wait: 20
    assert_no_text "Loading customers...", wait: 15

    click_button "Items"
    assert_text "Accounting Items", wait: 20
    assert_no_text "Loading accounting items...", wait: 15

    click_button "Settings"
    assert_text "Settings", wait: 20

    # Navigate back to Invoices
    click_button "Invoices"
    assert_text "Invoices", wait: 10
    assert_selector "#filter_unpaid", text: "Unpaid"
  end

  test "invoice template with data renders correctly in templates tab" do
    sign_in(@user)

    # Create a template with all required associations
    template = AccountingTestData.build_invoice_template_for(@user)

    visit accounting_index_path

    # Click Templates tab
    click_button "Templates"
    assert_text "Invoice Templates", wait: 10

    # Template should be visible
    assert_text template.name, wait: 5
    assert_text template.currency

    # Should have action buttons
    within "#invoice_template_#{template.id}_div" do
      # Edit and delete buttons should be present
      assert_selector "button[type='button']", minimum: 1
    end
  end

  test "customer data renders correctly in customers tab" do
    sign_in(@user)

    # Create a customer with address
    address = @user.addresses.create!(
      address_type: :customer,
      state: :active,
      name: "Customer Address",
      full_address: "Customer St\nBarcelona",
      country: "ES"
    )
    customer = @user.customers.create!(
      name: "Test Customer Corp",
      contact_email: "customer@example.com",
      address: address
    )

    visit accounting_index_path

    # Click Customers tab
    click_button "Customers"
    assert_text "Customers", wait: 15
    assert_no_text "Loading customers...", wait: 10

    # Customer should be visible
    assert_text "Test Customer Corp", wait: 5
  end

  test "accounting item data renders correctly in items tab" do
    sign_in(@user)

    # Create accounting items
    @user.accounting_items.create!(
      reference: "WEB-001",
      name: "Web Development",
      kind: :service,
      price: 15000,
      unit: "hour",
      currency: :EUR
    )

    visit accounting_index_path

    # Click Items tab
    click_button "Items"
    assert_text "Accounting Items", wait: 20
    assert_no_text "Loading accounting items...", wait: 15

    # Item should be visible
    assert_text "Web Development", wait: 5
  end

  test "empty states render correctly for all tabs" do
    # Create a user with no accounting data
    user = User.create!(
      email: "empty@example.com",
      password: "password123",
      name: "Empty User",
      access_confirmed: true
    )

    sign_in(user)
    visit accounting_index_path

    # Templates empty state
    click_button "Templates"
    assert_text "Invoice Templates", wait: 20
    assert_no_text "Loading invoice templates...", wait: 15
    assert_text "No invoice templates found", wait: 5

    # Customers empty state
    click_button "Customers"
    assert_text "Customers", wait: 20
    assert_no_text "Loading customers...", wait: 15
    assert_text "No customers found", wait: 5

    # Items empty state
    click_button "Items"
    assert_text "Accounting Items", wait: 20
    assert_no_text "Loading accounting items...", wait: 15
    assert_text "No accounting items found", wait: 5

    # Settings empty states
    click_button "Settings"
    assert_text "Settings", wait: 20
    assert_no_text "Loading tax brackets...", wait: 15
    assert_text "No tax brackets found", wait: 5
    assert_text "No addresses found", wait: 5
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password || "password123"
    click_button "Log in"

    # Wait for redirect after successful login
    assert_no_text "Log in to Doosr", wait: 5
  end
end
