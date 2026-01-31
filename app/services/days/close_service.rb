class Days::CloseService
  attr_reader :day

  def initialize(day:)
    @day = day
  end

  def call
    day.close!
    { success: true, day: day }
  rescue StandardError => e
    Rails.logger.error "Day close failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end
end
