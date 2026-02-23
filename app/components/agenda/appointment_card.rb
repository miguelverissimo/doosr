# frozen_string_literal: true

class ::Components::Agenda::AppointmentCard < ::Components::Base
  def initialize(post:)
    @post = post
    @entries = post.data["entries"] || []
  end

  def view_template
    div(class: "border rounded-lg bg-card text-card-foreground shadow-sm") do
      # Header
      div(class: "p-4 pb-2") do
        h3(class: "text-lg font-semibold leading-none tracking-tight") { "Appointments" }
        p(class: "text-sm text-muted-foreground mt-1") { "Today's calendar" }
      end

      # Content
      div(class: "p-4 pt-0") do
        if @entries.empty?
          p(class: "text-muted-foreground text-sm") { "No appointments" }
        else
          div(class: "space-y-3") do
            @entries.each do |entry|
              render_entry(entry)
            end
          end
        end
      end

      # Footer
      div(class: "p-4 pt-0 text-xs text-muted-foreground") do
        plain "Updated #{time_ago_in_words(@post.updated_at)} ago"
      end
    end
  end

  private

  def render_entry(entry)
    div(class: "flex items-start gap-3 p-2 rounded-md border bg-muted/50") do
      div(class: "flex-1") do
        div(class: "flex items-center gap-2") do
          p(class: "font-medium") { entry["title"] }
          if entry["calendar"].present?
            Badge(variant: :secondary, size: :sm) { entry["calendar"] }
          end
        end

        div(class: "flex items-center gap-2 text-sm text-muted-foreground mt-1") do
          render ::Components::Icon::Clock.new(size: "14", class: "shrink-0")
          span { format_time_range(entry["start_time"], entry["end_time"]) }
          span(class: "text-xs") { "(#{format_duration(entry['start_time'], entry['end_time'])})" }
        end

        if entry["url"].present?
          a(
            href: entry["url"],
            target: "_blank",
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 text-sm text-primary hover:underline mt-1"
          ) do
            render ::Components::Icon::ExternalLink.new(size: "14", class: "shrink-0")
            span { "Join meeting" }
          end
        end
      end
    end
  end

  def format_time_range(start_time, end_time)
    start_t = Time.iso8601(start_time).in_time_zone
    end_t = Time.iso8601(end_time).in_time_zone
    "#{start_t.strftime('%H:%M')} - #{end_t.strftime('%H:%M')}"
  rescue ArgumentError
    "Invalid time"
  end

  def format_duration(start_time, end_time)
    start_t = Time.iso8601(start_time)
    end_t = Time.iso8601(end_time)
    minutes = ((end_t - start_t) / 60).to_i

    if minutes >= 60
      hours = minutes / 60
      remaining_minutes = minutes % 60
      if remaining_minutes > 0
        "#{hours}h #{remaining_minutes}m"
      else
        "#{hours}h"
      end
    else
      "#{minutes}m"
    end
  rescue ArgumentError
    ""
  end

  def time_ago_in_words(time)
    view_context.time_ago_in_words(time)
  end
end
