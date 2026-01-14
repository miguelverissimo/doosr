# frozen_string_literal: true

class JournalRecoveryController < ApplicationController
  before_action :authenticate_user!
  before_action :require_journal_protection, only: [ :new, :create ]

  def new
    render Views::Journals::RecoveryForm.new
  end

  def create
    if params[:seed_phrase].blank?
      return render_recovery_form_with_errors([ "Seed phrase is required" ])
    end

    unless Journals::MnemonicService.validate(params[:seed_phrase])
      return render_recovery_form_with_errors([ "Invalid seed phrase. Please enter all 12 words." ])
    end

    if params[:password].blank?
      return render_recovery_form_with_errors([ "New password is required" ])
    end

    if params[:password] != params[:password_confirmation]
      return render_recovery_form_with_errors([ "Passwords do not match" ])
    end

    if params[:password].length < 8
      return render_recovery_form_with_errors([ "Password must be at least 8 characters" ])
    end

    begin
      update_password_with_seed_phrase

      invalidate_existing_sessions

      respond_to do |format|
        format.html { redirect_to journals_path, notice: "Password reset successfully!" }
        format.turbo_stream do
          if params[:from_tab].present?
            render turbo_stream: [
              turbo_stream.replace(
                ::Components::Settings::JournalProtectionTab::DIALOG_ID,
                render_to_string(::Components::Settings::JournalProtectionTab.new(user: current_user))
              ),
              turbo_stream.append("body", "<script>window.toast && window.toast('Password reset successfully!', { type: 'success' }); localStorage.removeItem('journalSessionToken');</script>")
            ]
          else
            render turbo_stream: [
              turbo_stream.append("body", "<script>window.toast && window.toast('Password reset successfully!', { type: 'success' }); window.location.href = '#{journals_path}';</script>")
            ]
          end
        end
      end
    rescue Journals::EncryptionService::DecryptionError => e
      render_recovery_form_with_errors([ "Invalid seed phrase. Could not decrypt your journal data." ])
    rescue Journals::MnemonicService::InvalidMnemonicError => e
      render_recovery_form_with_errors([ "Invalid seed phrase format." ])
    end
  end

  private

  def require_journal_protection
    unless current_user.journal_protection_enabled?
      redirect_to journals_path, alert: "Journal protection is not enabled"
    end
  end

  def update_password_with_seed_phrase
    salt = current_user.journal_encryption_salt
    new_password = params[:password]
    seed_phrase = params[:seed_phrase].strip.downcase.split(/\s+/).join(" ")

    # Derive new password key (this will encrypt the seed phrase)
    new_password_key = Journals::EncryptionService.derive_key(new_password, salt)

    # Encrypt seed phrase with new password
    new_encrypted_seed = Journals::EncryptionService.encrypt(seed_phrase, new_password_key)

    current_user.update!(
      journal_password_digest: ::BCrypt::Password.create(new_password),
      encrypted_seed_phrase: [ new_encrypted_seed[:ciphertext], new_encrypted_seed[:iv], new_encrypted_seed[:auth_tag] ].join(":")
    )

    # Journals remain encrypted with seed-derived key, no re-encryption needed
  end

  def invalidate_existing_sessions
    pattern = "journal_session:#{current_user.id}:*"
    Rails.cache.delete_matched(pattern)
    cookies.delete(:journal_session_token)
  end

  def render_recovery_form_with_errors(errors)
    respond_to do |format|
      format.html do
        render Views::Journals::RecoveryForm.new(errors: errors, seed_phrase: params[:seed_phrase])
      end
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: "recover",
              errors: errors
            ))
          )
        else
          render turbo_stream: turbo_stream.replace(
            "recovery_form_container",
            render_to_string(Views::Journals::RecoveryForm.new(errors: errors, seed_phrase: params[:seed_phrase]))
          )
        end
      end
    end
  end
end
