# frozen_string_literal: true

module Views
  module Items
    class BaseItem < ::Views::Base
      attr_reader :record, :day, :list, :is_public_list

      def initialize(record:, day: nil, list: nil, is_public_list: false)
        @record = record
        @day = day
        @list = list
        @is_public_list = is_public_list
      end

      def view_template
        div(
          id: container_id,
          class: item_classes,
          data: stimulus_data
        ) do
          render_icon
          render_content
          render_badges
          render_actions_menu
        end
      end

      # Subclasses MUST override these methods
      def item_classes
        raise NotImplementedError, "Subclass must implement item_classes"
      end

      def render_icon
        raise NotImplementedError, "Subclass must implement render_icon"
      end

      def render_content
        raise NotImplementedError, "Subclass must implement render_content"
      end

      def stimulus_data
        raise NotImplementedError, "Subclass must implement stimulus_data"
      end

      # Subclasses MAY override these methods (defaults provided)
      def render_badges
        # Default: no badges
      end

      def render_actions_menu
        div(class: "opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1") do
          Button(variant: :ghost, icon: true, size: :sm, class: "h-7 w-7") do
            render ::Components::Icon::MoreVertical.new(size: "14", class: "shrink-0")
          end
        end
      end

      def container_id
        "#{record.class.name.downcase}_#{record.id}"
      end
    end
  end
end
