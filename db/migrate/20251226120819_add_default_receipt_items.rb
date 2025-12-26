class AddDefaultReceiptItems < ActiveRecord::Migration[8.1]
  def up
    # For each user, create default receipt items
    User.find_each do |user|
      # Find or get the user's first tax bracket (or create a default one)
      tax_bracket = user.tax_brackets.find_by(name: "Exempt") || user.tax_brackets.create!(
        name: "Exempt",
        percentage: 0
      )
      
      # Create the 3 default receipt items
      default_items = [
        {
          reference: "OUT - MANEV-H",
          kind: "service",
          description: "Manutenção Evolutiva (Hora ou fracção)",
          unit: "hour",
          gross_unit_price: 6000, # 60.00 in cents
          tax_bracket: tax_bracket,
          exemption_motive: "a) IVA - autoliquidação - Artigo 6.º n.º 6 alínea a) do CIVA, a contrário",
          unit_price_with_tax: 6000, # 60.00 in cents
          active: true
        },
        {
          reference: "OUT - MANEV-ON-CALL",
          kind: "service",
          description: "Manutenção Evolutiva - On Call (Hora ou fracção)",
          unit: "hour",
          gross_unit_price: 9000, # 90.00 in cents
          tax_bracket: tax_bracket,
          exemption_motive: "a) IVA - autoliquidação - Artigo 6.º n.º 6 alínea a) do CIVA, a contrário",
          unit_price_with_tax: 9000, # 90.00 in cents
          active: true
        },
        {
          reference: "OUT - TOKEN",
          kind: "service",
          description: "Token ferramenta externa (IA, etc)",
          unit: "unit",
          gross_unit_price: 1, # 1 cent
          tax_bracket: tax_bracket,
          exemption_motive: "a) IVA - autoliquidação - Artigo 6.º n.º 6 alínea a) do CIVA, a contrário",
          unit_price_with_tax: 1, # 1 cent
          active: true
        },
      ]
      
      default_items.each do |item_attrs|
        user.receipt_items.find_or_create_by!(reference: item_attrs[:reference]) do |item|
          item.assign_attributes(item_attrs)
        end
      end
    end
  end
  
  def down
    # Remove default receipt items
    Accounting::ReceiptItem.where(reference: ["OUT - MANEV-H", "OUT - MANEV-ON-CALL", "OUT - TOKEN"]).destroy_all
  end
end