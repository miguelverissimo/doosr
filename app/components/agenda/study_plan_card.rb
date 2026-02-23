# frozen_string_literal: true

class ::Components::Agenda::StudyPlanCard < ::Components::Base
  def initialize(post:)
    @post = post
    @entries = post.data["entries"] || []
  end

  def view_template
    div(class: "border rounded-lg bg-card text-card-foreground shadow-sm") do
      # Header
      div(class: "p-4 pb-2") do
        h3(class: "text-lg font-semibold leading-none tracking-tight") { "Study Plan" }
        p(class: "text-sm text-muted-foreground mt-1") { "Today's learning goals" }
      end

      # Content
      div(class: "p-4 pt-0") do
        if @entries.empty?
          p(class: "text-muted-foreground text-sm") { "No study items" }
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
          Badge(variant: :outline, size: :sm) { entry["subject"] }
        end

        p(class: "font-medium mt-1") { entry["title"] }

        if entry["url"].present?
          a(
            href: entry["url"],
            target: "_blank",
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 text-sm text-primary hover:underline mt-1"
          ) do
            render ::Components::Icon::ExternalLink.new(size: "14", class: "shrink-0")
            span { "Open resource" }
          end
        end
      end
    end
  end

  def time_ago_in_words(time)
    view_context.time_ago_in_words(time)
  end
end
