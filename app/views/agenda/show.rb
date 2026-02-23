# frozen_string_literal: true

module Views
  module Agenda
    class Show < ::Views::Base
      def initialize(posts:)
        @posts = posts
        @posts_by_type = posts.index_by { |p| p.type.demodulize.underscore }
      end

      def view_template
        div(class: "flex h-full flex-col p-4") do
          h1(class: "text-2xl font-bold mb-4") { "Agenda" }

          if @posts.empty?
            render_empty_state
          else
            div(class: "grid gap-4 md:grid-cols-2") do
              render_appointment_card if @posts_by_type["appointment"]
              render_study_plan_card if @posts_by_type["study_plan"]
            end
          end
        end
      end

      private

      def render_empty_state
        div(class: "flex flex-col items-center justify-center py-12 text-muted-foreground") do
          render ::Components::Icon::Calendar.new(size: "48", class: "mb-4 opacity-50")
          p(class: "text-lg") { "No agenda posts yet" }
          p(class: "text-sm") { "Posts will appear here when created via the API" }
        end
      end

      def render_appointment_card
        post = @posts_by_type["appointment"]
        render ::Components::Agenda::AppointmentCard.new(post: post)
      end

      def render_study_plan_card
        post = @posts_by_type["study_plan"]
        render ::Components::Agenda::StudyPlanCard.new(post: post)
      end
    end
  end
end
