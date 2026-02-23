class ApiTokensController < ApplicationController
  before_action :authenticate_user!
  before_action { authorize! :access, :api }
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
    render ::Views::ApiTokens::Index.new(api_tokens: @api_tokens)
  end

  def create
    plain_token = ApiToken.generate_token
    scopes = Array(params[:scopes]).compact_blank
    @api_token = current_user.api_tokens.build(
      name: params[:name],
      scopes: scopes,
      token_digest: ApiToken.digest_token(plain_token),
      token_prefix: plain_token[0..11],
      token_encrypted: ApiToken.encrypt_token(plain_token)
    )
    @api_token.plain_token = plain_token

    if @api_token.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend(
              "api_tokens_list",
              render_to_string(::Components::ApiTokens::TokenRow.new(api_token: @api_token), layout: false)
            ),
            turbo_stream.update("no_tokens_message", ""),
            turbo_stream.append(
              "body",
              render_to_string(::Components::ApiTokens::TokenCreatedDialog.new(plain_token: plain_token, token_name: @api_token.name, scopes: scopes), layout: false)
            )
          ]
        end
        format.html { redirect_to api_tokens_path, notice: "API token created" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "token_form_errors",
            helpers.tag.p(@api_token.errors.full_messages.join(", "), class: "text-sm text-destructive")
          )
        end
        format.html { redirect_to api_tokens_path, alert: @api_token.errors.full_messages.join(", ") }
      end
    end
  end

  def destroy
    @api_token = current_user.api_tokens.find(params[:id])
    @api_token.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.remove("api_token_#{@api_token.id}")
        ]

        if current_user.api_tokens.count.zero?
          streams << turbo_stream.update(
            "no_tokens_message",
            helpers.tag.p("No API tokens yet. Create one to get started.", class: "text-sm text-muted-foreground")
          )
        end

        render turbo_stream: streams
      end
      format.html { redirect_to api_tokens_path, notice: "API token revoked" }
    end
  end
end
