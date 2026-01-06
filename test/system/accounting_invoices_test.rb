require "application_system_test_case"

class AccountingInvoicesTest < ApplicationSystemTestCase
  def setup
    @user = AccountingTestData.build_accounting_user_with_basic_invoicing
  end

  def test_user_can_view_invoices_index_and_from_template_button
    sign_in(@user)

    # Go directly to the Accounting section
    visit accounting_index_path

    # Wait for page to load
    assert_text "Invoicing", wait: 5
    assert_text "Invoices"
    assert_selector "a", text: "From Template"
    assert_selector "a", text: "Add Invoice"

    # Verify filter badges are present
    assert_selector "#filter_unpaid", text: "Unpaid"
    assert_selector "#filter_paid", text: "Paid"
    assert_selector "#filter_all", text: "All"
  end

  def test_user_can_create_invoice_from_template_via_dialog
    sign_in(@user)

    template = AccountingTestData.build_invoice_template_for(@user)

    visit accounting_index_path
    assert_text "Invoices", wait: 5

    # Wait for the "From Template" link to be present and clickable
    from_template_link = find("a", text: "From Template", wait: 5)

    # Open the From Template dialog (Turbo frame loads asynchronously)
    # Use execute_script to ensure the click happens even if there are overlay issues
    execute_script("arguments[0].click();", from_template_link)

    # Wait for the dialog to appear via Turbo frame
    # The dialog content is loaded into a turbo_frame, so we need to wait for it
    assert_text "Create Invoice from Template", wait: 10
    assert_text "Select Template"

    # Select the template (this triggers JavaScript to populate fields)
    select template.name, from: "invoice_template_id"

    # Wait for template info to populate
    assert_text "Provider Company", wait: 3
    assert_text "Acme Corp"

    # Wait for JavaScript to populate invoice items from template
    # The template should have added an item with "Consulting Service"
    assert_text "Consulting Service", wait: 5
    assert_text "€123.00", wait: 3  # Total should be calculated

    # Fill in required invoice fields
    fill_in "invoice_number", with: "1"
    fill_in "invoice_customer_reference", with: "Test reference"
    fill_in "invoice_notes", with: "Test notes"

    # Submit the form (Turbo Stream response)
    click_button "Create Invoice"

    # Wait for the loading state to disappear and dialog to close
    assert_no_text "Creating invoice from template...", wait: 10

    # Wait for Turbo Stream to update the page and show the invoice
    # The success message is in a JavaScript toast, so we check for the invoice instead
    assert_text "Invoice # 1/", wait: 5
    assert_text "Invoices"
  end

  private

  def sign_in(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"

    # Wait for redirect after successful login
    assert_no_text "Log in to Doosr", wait: 5
  end
end
