# frozen_string_literal: true

Rails.application.configure do
  # Log Solid Queue activity to STDOUT in development
  if Rails.env.development?
    config.solid_queue.silence_polling = false

    config.after_initialize do
      SolidQueue.logger = ActiveSupport::Logger.new($stdout).tap do |logger|
        logger.level = Logger::DEBUG
        logger.formatter = proc do |severity, datetime, _progname, msg|
          "[SolidQueue] #{datetime.strftime('%H:%M:%S')} #{severity}: #{msg}\n"
        end
      end
    end
  end
end
