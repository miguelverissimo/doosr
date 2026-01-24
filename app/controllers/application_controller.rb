class ApplicationController < ActionController::Base
  include MarkdownHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :journals_unlocked?

  def journals_unlocked?
    return false unless current_user&.journal_protection_enabled?

    session_token = cookies.encrypted[:journal_session_token]
    return false if session_token.blank?

    cache_key = "journal_session:#{current_user.id}:#{session_token}"
    session_data = Rails.cache.read(cache_key)
    return false unless session_data
    return false unless session_data[:user_id] == current_user.id
    return false if session_data[:last_activity_at].nil?

    timeout_minutes = current_user.journal_session_timeout_minutes
    last_activity = Time.at(session_data[:last_activity_at])
    Time.current - last_activity <= timeout_minutes.minutes
  end
end
