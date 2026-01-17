# frozen_string_literal: true

class ::Components::NotificationBadge < ::Components::Base
  def initialize(count:, **attrs)
    @count = count
    super(**attrs)
  end

  def view_template
    return if count.zero?

    span(
      class: [
        "absolute -top-1 -right-1 flex items-center justify-center",
        "min-w-[18px] h-[18px] px-1",
        "text-xs font-medium text-white",
        "bg-destructive rounded-full",
        "ring-2 ring-background"
      ]
    ) do
      plain display_count
    end
  end

  private

  attr_reader :count

  def display_count
    count > 99 ? "99+" : count.to_s
  end
end
