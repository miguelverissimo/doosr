# Make the session cookie persistent so PWA users stay logged in.
# Without an explicit expire_after, Rails sets a session-only cookie (no Expires attribute),
# which browsers/PWAs clear when the app is closed.
Rails.application.config.session_store :cookie_store,
  key: "_doosr_session",
  expire_after: 1.year
