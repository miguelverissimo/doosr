module Accounting
  class InvoicesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_invoice, only: [ :destroy, :preview, :pdf ]

    def index
      @invoices = current_user.invoices
    end

    def preview
      @invoice = current_user.invoices
        .includes(
          :provider, :customer, :bank_info,
          invoice_items: [ :item, :tax_bracket ],
          invoice_template: [ :accounting_logo ]
        )
        .find(params[:id])
      render Views::Accounting::Invoices::Preview.new(invoice: @invoice), layout: false
    end

    def pdf
      @invoice = current_user.invoices
        .includes(
          :provider, :customer, :bank_info,
          invoice_items: [ :item, :tax_bracket ],
          invoice_template: [ :accounting_logo ]
        )
        .find(params[:id])

      # Render the Phlex component to HTML
      html = render_to_string(
        Views::Accounting::Invoices::Preview.new(invoice: @invoice),
        layout: false
      )

      # Read and inline the CSS (Grover needs inline styles)
      css_path = Rails.root.join("app/assets/stylesheets/invoice_preview.css")
      css_content = File.exist?(css_path) ? File.read(css_path) : ""

      # Remove stylesheet link tag and inline CSS instead
      html_with_css = html
        .gsub(/<link[^>]*stylesheet[^>]*>/i, "")
        .sub("</head>", "<style>#{css_content}</style></head>")

      # Convert Active Storage images to data URIs (base64) for PDF
      if @invoice.invoice_template&.accounting_logo&.image&.attached?
        logo = @invoice.invoice_template.accounting_logo
        begin
          # Download the image
          image_data = logo.image.download
          # Get the content type
          content_type = logo.image.content_type
          # Encode to base64
          base64_image = Base64.strict_encode64(image_data)
          # Create data URI
          data_uri = "data:#{content_type};base64,#{base64_image}"
          
          # Replace the Active Storage URL with the data URI
          html_with_css = html_with_css.gsub(
            /src="[^"]*active_storage[^"]*"/,
            "src=\"#{data_uri}\""
          )
        rescue => e
          Rails.logger.error "Failed to embed logo: #{e.message}"
        end
      end

      # Convert any remaining relative URLs to absolute URLs
      base_url = "#{request.protocol}#{request.host_with_port}"
      html_final = html_with_css.gsub(/src="(\/[^"]+)"/) do |match|
        url = $1
        full_url = url.start_with?('http') ? url : "#{base_url}#{url}"
        "src=\"#{full_url}\""
      end

      # Convert to PDF using Grover (Chromium-based, supports modern CSS)
      grover_options = {
        content: html_final,
        format: 'A4',
        viewport: { width: 1280, height: 1024 },
        print_background: true,
        wait_until: 'networkidle0'  # Wait for all resources (including images) to load
      }
      
      # Add launch args for production (Docker/container environments)
      # Chromium needs --no-sandbox when running in containers without proper sandbox support
      if Rails.env.production?
        grover_options[:args] = ['--no-sandbox', '--disable-setuid-sandbox']
      end
      
      pdf = Grover.new(grover_options).to_pdf

      filename = "Invoice_#{@invoice.display_number.gsub('/', '-')}.pdf"
      send_data(pdf, filename: filename, type: 'application/pdf', disposition: 'attachment')
    end

    def create
      # Split out nested invoice_items_attributes so we don't assign them
      # directly (we build invoice_items manually below).
      raw_params = invoice_params
      invoice_item_params = raw_params.delete(:invoice_items_attributes)

      @invoice = current_user.invoices.new(raw_params)
      @invoice.user = current_user
      @invoice.state = :draft

      # Generate invoice number and display_number
      if invoice_params[:invoice_template_id].present?
        template = current_user.invoice_templates.find(invoice_params[:invoice_template_id])
        @invoice.invoice_template = template
        @invoice.provider_id ||= template.provider_address_id
        @invoice.customer_id ||= template.customer_id
        @invoice.currency ||= template.currency
        @invoice.bank_info_id ||= template.bank_info_id
      end

      # Generate number (sequence per user per year, reset to 1 each year)
      # Use the invoice issue date year if present, otherwise use current year
      invoice_year = if @invoice.issued_at.present?
                       # Handle both DateTime objects and date strings
                       date = @invoice.issued_at.is_a?(String) ? Date.parse(@invoice.issued_at) : @invoice.issued_at.to_date
                       date.year
                     else
                       Date.today.year
                     end
      @invoice.year = invoice_year

      last_invoice = current_user.invoices
        .where(year: invoice_year)
        .order(number: :desc)
        .first

      @invoice.number = last_invoice ? last_invoice.number + 1 : 1
      @invoice.display_number = "#{@invoice.number}/#{invoice_year}"

      # Build invoice items from nested attributes
      if invoice_item_params.present?
        invoice_item_params.each do |_index, item_params|
          next if item_params[:_destroy] == "1" || item_params[:item_id].blank?

          accounting_item = current_user.accounting_items.find_by(id: item_params[:item_id])
          tax_bracket = current_user.tax_brackets.find_by(id: item_params[:tax_bracket_id])

          next unless accounting_item && tax_bracket

          # Base description comes from the accounting item (tokens live there),
          # falling back to the accounting item name.
          raw_description =
            accounting_item.description.presence ||
            accounting_item.name

          interpolated_description =
            InvoiceDescriptionTokens.interpolate_description(raw_description, @invoice)

          @invoice.invoice_items.build(
            user: current_user,
            item: accounting_item,
            tax_bracket: tax_bracket,
            description: interpolated_description,
            quantity: item_params[:quantity],
            unit: item_params[:unit] || accounting_item.unit,
            unit_price: item_params[:unit_price],
            subtotal: item_params[:subtotal],
            discount_rate: item_params[:discount_rate] || 0,
            discount_amount: item_params[:discount_amount] || 0,
            tax_rate: tax_bracket.percentage,
            tax_amount: item_params[:tax_amount] || 0,
            amount: item_params[:amount]
          )
        end
      end

      respond_to do |format|
        if @invoice.save
          # For Turbo requests, do a full redirect to the main accounting
          # page, which by default shows the Invoicing -> Invoices tab,
          # ensuring the user actually lands on the invoices list.
          format.turbo_stream do
            redirect_to accounting_index_path, notice: "Invoice created successfully."
          end
          format.html { redirect_to accounting_index_path, notice: "Invoice created successfully." }
        else
          format.turbo_stream do
            error_message = @invoice.errors.full_messages.join(", ")
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create invoice: #{error_message}', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to create invoice" }
        end
      end
    end

    def destroy
      @invoice = current_user.invoices.find(params[:id])

      respond_to do |format|
        if @invoice.destroy
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("invoices_list", Views::Accounting::Invoices::ListContent.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Invoice deleted successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Invoice deleted successfully." }
        else
          format.turbo_stream do
            message = "Failed to delete invoice: #{@invoice.errors.full_messages.join(', ')}"
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('#{message}', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to delete invoice" }
        end
      end
    end

    def update
      @invoice = current_user.invoices.find(params[:id])

      new_state = params[:state]

      respond_to do |format|
        if new_state.present?
          # Simple state transition update
          if Accounting::Invoice.states.key?(new_state) && @invoice.update(state: new_state)
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("invoices_list", Views::Accounting::Invoices::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Invoice updated successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Invoice updated successfully." }
          else
            format.turbo_stream do
              message = "Failed to update invoice: invalid state"
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('#{message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to update invoice" }
          end
        else
          # Full invoice edit (from dialog form)
          attrs = invoice_params.except(:invoice_items_attributes, :invoice_template_id)
          invoice_item_params = invoice_params[:invoice_items_attributes]

          success = false

          ActiveRecord::Base.transaction do
            unless @invoice.update(attrs)
              raise ActiveRecord::Rollback
            end

            if invoice_item_params.present?
              # Replace all invoice items with the submitted ones
              @invoice.invoice_items.destroy_all

              invoice_item_params.each do |_index, item_params|
                next if item_params[:_destroy] == "1" || item_params[:item_id].blank?

                accounting_item = current_user.accounting_items.find_by(id: item_params[:item_id])
                tax_bracket = current_user.tax_brackets.find_by(id: item_params[:tax_bracket_id])

                next unless accounting_item && tax_bracket

                raw_description =
                  item_params[:description].presence ||
                  accounting_item.description.presence ||
                  accounting_item.name

                interpolated_description =
                  InvoiceDescriptionTokens.interpolate_description(raw_description, @invoice)

                @invoice.invoice_items.build(
                  user: current_user,
                  item: accounting_item,
                  tax_bracket: tax_bracket,
                  description: interpolated_description,
                  quantity: item_params[:quantity],
                  unit: item_params[:unit] || accounting_item.unit,
                  unit_price: item_params[:unit_price],
                  subtotal: item_params[:subtotal],
                  discount_rate: item_params[:discount_rate] || 0,
                  discount_amount: item_params[:discount_amount] || 0,
                  tax_rate: tax_bracket.percentage,
                  tax_amount: item_params[:tax_amount] || 0,
                  amount: item_params[:amount]
                )
              end

              unless @invoice.save
                raise ActiveRecord::Rollback
              end
            end

            success = true
          end

          if success
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("invoices_list", Views::Accounting::Invoices::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Invoice updated successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Invoice updated successfully." }
          else
            format.turbo_stream do
              message = "Failed to update invoice: #{@invoice.errors.full_messages.join(', ')}"
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('#{message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to update invoice" }
          end
        end
      end
    end

    private

    def set_invoice
      @invoice = current_user.invoices.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounting_index_path, alert: "Invoice not found"
    end

    def invoice_params
      params.require(:invoice).permit(
        :invoice_template_id,
        :number,
        :provider_id,
        :customer_id,
        :currency,
        :bank_info_id,
        :issued_at,
        :due_at,
        :notes,
        :customer_reference,
        invoice_items_attributes: [
          :item_id,
          :quantity,
          :discount_rate,
          :tax_bracket_id,
          :description,
          :unit,
          :unit_price,
          :subtotal,
          :discount_amount,
          :tax_rate,
          :tax_amount,
          :amount,
          :_destroy
        ]
      )
    end
  end
end
