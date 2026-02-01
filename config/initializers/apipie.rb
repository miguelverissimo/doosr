Apipie.configure do |config|
  config.app_name = "Doosr API"
  config.default_version = "v1"
  config.api_base_url["v1"] = "/api/v1"
  config.doc_base_url = "/api/docs"
  config.api_controllers_matcher = Rails.root.join("app", "controllers", "api", "**", "*.rb").to_s
  config.validate = false
  config.translate = false
  config.app_info["v1"] = "Doosr API v1 — Daily task management, lists, notes, journals, checklists, banking, and accounting."
end
