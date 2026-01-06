class AccountingTestData
  def self.build_accounting_user_with_basic_invoicing
    new.build_accounting_user_with_basic_invoicing
  end

  def self.build_invoice_template_for(user)
    new.build_invoice_template_for(user)
  end

  def build_accounting_user_with_basic_invoicing
    user = User.create!(
      email: "accounting@example.com",
      password: "password123",
      roles: [ "accounting" ]
    )

    # Provider address (used as invoice provider)
    Address.create!(
      user: user,
      address_type: :user,
      state: :active,
      name: "Provider Company",
      full_address: "123 Main Street\nCity",
      country: "PT"
    )

    # Customer with its own address
    customer_address = Address.create!(
      user: user,
      address_type: :customer,
      state: :active,
      name: "Customer Company",
      full_address: "456 Customer Road\nCity",
      country: "PT"
    )

    Accounting::Customer.create!(
      user: user,
      address: customer_address,
      name: "Acme Corp"
    )

    # Simple accounting logo for templates
    Accounting::AccountingLogo.create!(
      user: user,
      title: "Default Logo"
    )

    # Basic tax bracket and accounting item used in templates/invoices
    Accounting::TaxBracket.create!(
      user: user,
      name: "Standard Tax",
      percentage: 23
    )

    Accounting::AccountingItem.create!(
      user: user,
      reference: "SERV-001",
      name: "Consulting Service",
      kind: :service,
      unit: "hour",
      price: 10_000, # cents
      currency: :EUR
    )

    user
  end

  def build_invoice_template_for(user)
    logo = user.accounting_logos.first
    provider_address = user.addresses.where(address_type: :user).first
    customer = user.customers.first
    accounting_item = user.accounting_items.first
    tax_bracket = user.tax_brackets.first

    template = Accounting::InvoiceTemplate.create!(
      user: user,
      accounting_logo: logo,
      provider_address: provider_address,
      customer: customer,
      currency: :EUR,
      name: "Standard Template",
      description: "Standard consulting invoice"
    )

    Accounting::InvoiceTemplateItem.create!(
      invoice_template: template,
      user: user,
      item: accounting_item,
      tax_bracket: tax_bracket,
      quantity: 1,
      unit: "hour",
      discount_rate: 0
    )

    template
  end
end


