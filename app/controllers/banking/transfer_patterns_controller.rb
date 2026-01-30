# frozen_string_literal: true

module Banking
  class TransferPatternsController < BaseController
    before_action :set_transfer_pattern, only: [ :edit, :update, :destroy ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @transfer_patterns = load_transfer_patterns_with_counts

      respond_to do |format|
        format.turbo_stream do
          if params[:content_only]
            render turbo_stream: turbo_stream.replace(
              "transfer_patterns_content",
              render_to_string(::Views::Banking::TransferPatterns::List.new(transfer_patterns: @transfer_patterns), layout: false)
            )
          else
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::Banking::TransferPatterns::IndexDialog.new(transfer_patterns: @transfer_patterns), layout: false)
            )
          end
        end
      end
    end

    def new
      @transfer_pattern = current_user.transfer_patterns.build

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transfer_patterns_content",
            render_to_string(::Views::Banking::TransferPatterns::Form.new(transfer_pattern: @transfer_pattern), layout: false)
          )
        end
      end
    end

    def create
      @transfer_pattern = current_user.transfer_patterns.build(transfer_pattern_params)

      if @transfer_pattern.save
        applied_count = apply_to_existing_if_requested
        @transfer_patterns = load_transfer_patterns_with_counts

        respond_to do |format|
          format.turbo_stream do
            streams = [
              turbo_stream.replace(
                "transfer_patterns_content",
                render_to_string(::Views::Banking::TransferPatterns::List.new(transfer_patterns: @transfer_patterns), layout: false)
              )
            ]

            if applied_count.positive?
              toast_message = "Pattern created and applied to #{applied_count} existing transaction#{'s' if applied_count != 1}"
              streams << turbo_stream.append(
                "body",
                "<script>window.toast && window.toast('#{toast_message}', { type: 'success' })</script>"
              )
            end

            render turbo_stream: streams
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "transfer_pattern_form_errors",
              "<div class='text-sm text-destructive'>#{@transfer_pattern.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transfer_patterns_content",
            render_to_string(::Views::Banking::TransferPatterns::Form.new(transfer_pattern: @transfer_pattern), layout: false)
          )
        end
      end
    end

    def update
      if @transfer_pattern.update(transfer_pattern_params)
        rematch_transactions_for_pattern(@transfer_pattern)
        @transfer_patterns = load_transfer_patterns_with_counts

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "transfer_patterns_content",
              render_to_string(::Views::Banking::TransferPatterns::List.new(transfer_patterns: @transfer_patterns), layout: false)
            )
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "transfer_pattern_form_errors",
              "<div class='text-sm text-destructive'>#{@transfer_pattern.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      # Unmark transactions that matched this pattern
      current_user.bank_transactions
        .where(is_transfer: true)
        .where("LOWER(description) LIKE ?", "%#{@transfer_pattern.pattern.downcase}%")
        .update_all(is_transfer: false)

      @transfer_pattern.destroy!
      @transfer_patterns = load_transfer_patterns_with_counts

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transfer_patterns_content",
            render_to_string(::Views::Banking::TransferPatterns::List.new(transfer_patterns: @transfer_patterns), layout: false)
          )
        end
      end
    end

    private

    def set_transfer_pattern
      @transfer_pattern = current_user.transfer_patterns.find(params[:id])
    end

    def load_transfer_patterns_with_counts
      # Count matching transactions for each pattern
      patterns = current_user.transfer_patterns.by_length_desc

      patterns.map do |pattern|
        count = current_user.bank_transactions
          .where(is_transfer: true)
          .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
          .count
        pattern.define_singleton_method(:matched_transactions_count) { count }
        pattern
      end
    end

    def transfer_pattern_params
      params.require(:transfer_pattern).permit(:pattern, :label)
    end

    def apply_to_existing_if_requested
      return 0 unless params[:apply_to_existing] == "1"

      count = current_user.bank_transactions
        .where(is_transfer: false)
        .where("LOWER(description) LIKE ?", "%#{@transfer_pattern.pattern.downcase}%")
        .update_all(is_transfer: true)

      count
    end

    def rematch_transactions_for_pattern(pattern)
      # 1. For transactions currently marked as transfers that matched the OLD pattern,
      # check if they still match and unmark if not
      # 2. For transactions not marked as transfers, check if they match the new pattern

      # Since we can't easily track which transactions were marked by which pattern,
      # we'll do a simple approach: mark all matching transactions as transfers
      current_user.bank_transactions
        .where(is_transfer: false)
        .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
        .update_all(is_transfer: true)
    end
  end
end
