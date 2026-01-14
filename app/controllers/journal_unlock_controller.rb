# frozen_string_literal: true

class JournalUnlockController < ApplicationController
  before_action :authenticate_user!

  def new
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Journals::UnlockDialog.new)
        )
      end
    end
  end

  def create
    password = params[:password]

    if password.blank?
      return render_error("Password is required")
    end

    unless current_user.journal_protection_enabled?
      return render_error("Journal protection is not enabled")
    end

    stored_password = ::BCrypt::Password.new(current_user.journal_password_digest)
    unless stored_password == password
      return render_error("Invalid password")
    end

    session_token = generate_session_token

    # Decrypt seed phrase with password
    salt = current_user.journal_encryption_salt
    password_key = Journals::EncryptionService.derive_key(password, salt)

    encrypted_seed_parts = current_user.encrypted_seed_phrase.split(":")
    seed_phrase = Journals::EncryptionService.decrypt(
      encrypted_seed_parts[0],
      encrypted_seed_parts[1],
      password_key,
      auth_tag: encrypted_seed_parts[2]
    )

    # Derive encryption key from seed phrase
    encryption_key = Journals::EncryptionService.derive_key(seed_phrase, salt)

    cache_key = journal_session_cache_key(session_token)
    Rails.cache.write(
      cache_key,
      {
        user_id: current_user.id,
        encryption_key: Base64.strict_encode64(encryption_key),
        last_activity_at: Time.current.to_i
      },
      expires_in: 24.hours
    )

    # Store token in cookie for automatic inclusion in all requests
    cookies.encrypted[:journal_session_token] = {
      value: session_token,
      expires: 24.hours.from_now,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }

    # Set encryption key in Current for this request
    Current.encryption_key = encryption_key

    # Get the journal ID from the referer URL
    journal_id = extract_journal_id_from_referer
    if journal_id.blank?
      return respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.action(:redirect, journals_path)
        end
      end
    end

    # Load the journal with unlocked content
    @journal = current_user.journals.find(journal_id)
    result = ::Journals::OpenOrCreateService.call(user: current_user, date: @journal.date)
    @journal = result[:journal]
    @tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("journal_unlock_dialog"),
          turbo_stream.replace(
            "journal_content",
            render_to_string(::Views::Journals::Show.new(journal: @journal, tree: @tree), layout: false)
          ),
          turbo_stream.append("body", <<~SCRIPT.html_safe)
            <script>
              window.dispatchEvent(new CustomEvent('journal:unlocked'));
              window.toast && window.toast('Journal unlocked successfully', { type: 'success' });
            </script>
          SCRIPT
        ]
      end
    end
  end

  private

  def generate_session_token
    SecureRandom.urlsafe_base64(32)
  end

  def journal_session_cache_key(token)
    "journal_session:#{current_user.id}:#{token}"
  end

  def extract_journal_id_from_referer
    return nil unless request.referer.present?

    # Extract ID from URLs like /journals/123
    match = request.referer.match(%r{/journals/(\d+)})
    match[1] if match
  end

  def render_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "journal_unlock_dialog",
          render_to_string(::Views::Journals::UnlockDialog.new(error: message))
        )
      end
    end
  end
end
