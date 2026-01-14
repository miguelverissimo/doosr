# frozen_string_literal: true

class JournalProtectionController < ApplicationController
  before_action :authenticate_user!

  def show
    respond_to do |format|
      format.html do
        if params[:tab_form].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: params[:tab_form]
            ))
          )
        elsif params[:cancel_tab].present?
          # Handle cancel - render tab in initial state
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user
            ))
          )
        else
          render ::Views::JournalProtection::Show.new(user: current_user)
        end
      end
      format.turbo_stream do
        if params[:tab_form].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: params[:tab_form]
            ))
          )
        elsif params[:cancel_tab].present?
          # Handle cancel - render tab in initial state
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user
            ))
          )
        else
          case params[:action_type]
          when "enable"
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::JournalProtection::EnableDialog.new)
            )
          when "change_password"
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::JournalProtection::ChangePasswordDialog.new)
            )
          when "disable"
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::JournalProtection::DisableDialog.new)
            )
          else
            head :bad_request
          end
        end
      end
    end
  end

  def create
    case params[:step]
    when "generate_seed"
      handle_generate_seed
    when "confirm_seed"
      handle_confirm_seed
    else
      redirect_to journal_protection_settings_path, alert: "Invalid request"
    end
  end

  def update
    unless current_user.journal_protection_enabled?
      return redirect_to journal_protection_settings_path, alert: "Journal protection is not enabled."
    end

    if params[:current_password].blank?
      return render_change_password_form_with_errors([ "Current password is required" ])
    end

    unless ::BCrypt::Password.new(current_user.journal_password_digest) == params[:current_password]
      return render_change_password_form_with_errors([ "Current password is incorrect" ])
    end

    if params[:new_password].blank?
      return render_change_password_form_with_errors([ "New password is required" ])
    end

    if params[:new_password] != params[:new_password_confirmation]
      return render_change_password_form_with_errors([ "New passwords do not match" ])
    end

    if params[:new_password].length < 8
      return render_change_password_form_with_errors([ "New password must be at least 8 characters" ])
    end

    salt = current_user.journal_encryption_salt

    # Derive password keys (not journal encryption keys)
    old_password_key = Journals::EncryptionService.derive_key(params[:current_password], salt)
    new_password_key = Journals::EncryptionService.derive_key(params[:new_password], salt)

    # Decrypt seed phrase with old password
    encrypted_seed_parts = current_user.encrypted_seed_phrase.split(":")
    seed_plaintext = Journals::EncryptionService.decrypt(
      encrypted_seed_parts[0],
      encrypted_seed_parts[1],
      old_password_key,
      auth_tag: encrypted_seed_parts[2]
    )

    # Re-encrypt seed phrase with new password
    new_encrypted_seed = Journals::EncryptionService.encrypt(seed_plaintext, new_password_key)

    current_user.update!(
      journal_password_digest: ::BCrypt::Password.create(params[:new_password]),
      encrypted_seed_phrase: [ new_encrypted_seed[:ciphertext], new_encrypted_seed[:iv], new_encrypted_seed[:auth_tag] ].join(":")
    )

    # No need to re-encrypt journals - they stay encrypted with seed-derived key

    Rails.cache.delete_matched("journal_session:#{current_user.id}:*")
    cookies.delete(:journal_session_token)

    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: [
            turbo_stream.replace(
              ::Components::Settings::JournalProtectionTab::DIALOG_ID,
              render_to_string(::Components::Settings::JournalProtectionTab.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Password changed successfully!', { type: 'success' }); localStorage.removeItem('journalSessionToken');</script>")
          ]
        else
          render turbo_stream: [
            turbo_stream.remove("change_password_dialog"),
            turbo_stream.replace(
              "journal_protection_content",
              render_to_string(::Views::JournalProtection::Show.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Password changed successfully!', { type: 'success' }); localStorage.removeItem('journalSessionToken');</script>")
          ]
        end
      end
    end
  end

  def destroy
    unless current_user.journal_protection_enabled?
      return redirect_to journal_protection_settings_path, alert: "Journal protection is not enabled."
    end

    if params[:current_password].blank?
      return render_disable_form_with_errors([ "Password is required" ])
    end

    unless ::BCrypt::Password.new(current_user.journal_password_digest) == params[:current_password]
      return render_disable_form_with_errors([ "Password is incorrect" ])
    end

    salt = current_user.journal_encryption_salt

    # Decrypt seed phrase with password
    password_key = Journals::EncryptionService.derive_key(params[:current_password], salt)

    encrypted_seed_parts = current_user.encrypted_seed_phrase.split(":")
    seed_phrase = Journals::EncryptionService.decrypt(
      encrypted_seed_parts[0],
      encrypted_seed_parts[1],
      password_key,
      auth_tag: encrypted_seed_parts[2]
    )

    # Derive encryption key from seed phrase
    encryption_key = Journals::EncryptionService.derive_key(seed_phrase, salt)

    Journals::BulkDecryptJob.perform_later(current_user.id, encryption_key)

    current_user.update!(
      journal_password_digest: nil,
      encrypted_seed_phrase: nil,
      journal_encryption_salt: nil,
      journal_protection_enabled: false
    )

    Rails.cache.delete_matched("journal_session:#{current_user.id}:*")
    cookies.delete(:journal_session_token)

    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: [
            turbo_stream.replace(
              ::Components::Settings::JournalProtectionTab::DIALOG_ID,
              render_to_string(::Components::Settings::JournalProtectionTab.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Journal protection disabled! Decrypting entries in the background...', { type: 'success' }); localStorage.removeItem('journalSessionToken');</script>")
          ]
        else
          render turbo_stream: [
            turbo_stream.remove("disable_protection_dialog"),
            turbo_stream.replace(
              "journal_protection_content",
              render_to_string(::Views::JournalProtection::Show.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Journal protection disabled! Decrypting entries in the background...', { type: 'success' }); localStorage.removeItem('journalSessionToken');</script>")
          ]
        end
      end
    end
  end

  def update_session_timeout
    timeout_minutes = params[:session_timeout_minutes].to_i

    if timeout_minutes < 5 || timeout_minutes > 1440
      return render_session_timeout_form_with_errors([ "Session timeout must be between 5 and 1440 minutes" ])
    end

    current_user.update!(journal_session_timeout_minutes: timeout_minutes)

    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: [
            turbo_stream.replace(
              ::Components::Settings::JournalProtectionTab::DIALOG_ID,
              render_to_string(::Components::Settings::JournalProtectionTab.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Session timeout updated to #{timeout_minutes} minutes', { type: 'success' });</script>")
          ]
        else
          render turbo_stream: [
            turbo_stream.replace(
              "journal_protection_content",
              render_to_string(::Views::JournalProtection::Show.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Session timeout updated to #{timeout_minutes} minutes', { type: 'success' });</script>")
          ]
        end
      end
    end
  end

  private

  def handle_generate_seed
    if params[:password].blank?
      return render_enable_form_with_errors([ "Password is required" ])
    end

    if params[:password] != params[:password_confirmation]
      return render_enable_form_with_errors([ "Passwords do not match" ])
    end

    if params[:password].length < 8
      return render_enable_form_with_errors([ "Password must be at least 8 characters" ])
    end

    salt = Journals::EncryptionService.generate_salt
    seed_phrase = Journals::MnemonicService.generate

    session[:journal_protection_salt] = salt
    session[:journal_protection_password] = params[:password]

    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: "enable",
              seed_phrase: seed_phrase
            ))
          )
        else
          render turbo_stream: turbo_stream.replace(
            "enable_protection_dialog",
            render_to_string(::Views::JournalProtection::EnableDialog.new(seed_phrase: seed_phrase))
          )
        end
      end
    end
  end

  def handle_confirm_seed
    salt = session[:journal_protection_salt]
    password = session[:journal_protection_password]
    seed_phrase = params[:seed_phrase]

    if salt.blank? || password.blank?
      return redirect_to journal_protection_settings_path, alert: "Session expired. Please try again."
    end

    if seed_phrase.blank?
      return redirect_to journal_protection_settings_path, alert: "Invalid seed phrase."
    end

    # Derive encryption key from seed phrase (this encrypts journal content)
    encryption_key = Journals::EncryptionService.derive_key(seed_phrase, salt)

    # Derive password key (this encrypts the seed phrase)
    password_key = Journals::EncryptionService.derive_key(password, salt)

    # Encrypt seed phrase with password key
    encrypted_seed = Journals::EncryptionService.encrypt(seed_phrase, password_key)

    current_user.update!(
      journal_encryption_salt: salt,
      journal_password_digest: ::BCrypt::Password.create(password),
      encrypted_seed_phrase: [ encrypted_seed[:ciphertext], encrypted_seed[:iv], encrypted_seed[:auth_tag] ].join(":"),
      journal_protection_enabled: true
    )

    Journals::BulkEncryptJob.perform_later(current_user.id, encryption_key)

    session.delete(:journal_protection_salt)
    session.delete(:journal_protection_password)

    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: [
            turbo_stream.replace(
              ::Components::Settings::JournalProtectionTab::DIALOG_ID,
              render_to_string(::Components::Settings::JournalProtectionTab.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Journal protection enabled! Encrypting existing entries in the background...', { type: 'success' });</script>")
          ]
        else
          render turbo_stream: [
            turbo_stream.remove("enable_protection_dialog"),
            turbo_stream.replace(
              "journal_protection_content",
              render_to_string(::Views::JournalProtection::Show.new(user: current_user))
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Journal protection enabled! Encrypting existing entries in the background...', { type: 'success' });</script>")
          ]
        end
      end
    end
  end

  def render_enable_form_with_errors(errors)
    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: "enable",
              errors: errors
            ))
          )
        else
          render turbo_stream: turbo_stream.replace(
            "enable_protection_dialog",
            render_to_string(::Views::JournalProtection::EnableDialog.new(errors: errors))
          )
        end
      end
    end
  end

  def render_change_password_form_with_errors(errors)
    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: "change_password",
              errors: errors
            ))
          )
        else
          render turbo_stream: turbo_stream.replace(
            "change_password_dialog",
            render_to_string(::Views::JournalProtection::ChangePasswordDialog.new(errors: errors))
          )
        end
      end
    end
  end

  def render_disable_form_with_errors(errors)
    respond_to do |format|
      format.turbo_stream do
        if params[:from_tab].present?
          render turbo_stream: turbo_stream.replace(
            ::Components::Settings::JournalProtectionTab::DIALOG_ID,
            render_to_string(::Components::Settings::JournalProtectionTab.new(
              user: current_user,
              active_form: "disable",
              errors: errors
            ))
          )
        else
          render turbo_stream: turbo_stream.replace(
            "disable_protection_dialog",
            render_to_string(::Views::JournalProtection::DisableDialog.new(errors: errors))
          )
        end
      end
    end
  end

  def render_session_timeout_form_with_errors(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          ::Components::Settings::JournalProtectionTab::DIALOG_ID,
          render_to_string(::Components::Settings::JournalProtectionTab.new(
            user: current_user,
            active_form: "session_timeout",
            errors: errors
          ))
        )
      end
    end
  end
end
