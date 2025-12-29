# frozen_string_literal: true

# Configure Grover for PDF generation
# In production (Docker/container environments), Chrome/Chromium needs
# additional flags to run without sandbox support
Grover.configure do |config|
  if Rails.env.production?
    config.options = {
      launch_args: [
        "--no-sandbox",                  # Required for containers without sandbox support
        "--disable-setuid-sandbox",      # Disable setuid sandbox
        "--disable-dev-shm-usage",       # Overcome limited /dev/shm in containers
        "--disable-gpu",                 # Disable GPU hardware acceleration
        "--disable-software-rasterizer", # Disable software rasterizer
        "--disable-extensions",          # Disable extensions
        "--no-first-run",               # Skip first run tasks
        "--no-zygote",                  # Disable zygote process (can help in containers)
        "--single-process"              # Run in single process mode (last resort, use if above doesn't work)
      ]
    }
  end
end
