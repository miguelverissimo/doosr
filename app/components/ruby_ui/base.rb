# frozen_string_literal: true

require "tailwind_merge"

module RubyUI
  class Base < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    TAILWIND_MERGER = ::TailwindMerge::Merger.new.freeze unless defined?(TAILWIND_MERGER)

    attr_reader :attrs

    def initialize(**user_attrs)
      @attrs = default_attrs.merge(user_attrs) do |key, default_val, user_val|
        if key == :class
          [ default_val, user_val ].flatten.compact
        elsif key == :data && default_val.is_a?(Hash) && user_val.is_a?(Hash)
          default_val.merge(user_val) do |k, old_v, new_v|
            k == :action ? [ old_v, new_v ].join(" ") : new_v
          end
        else
          user_val
        end
      end
      @attrs[:class] = TAILWIND_MERGER.merge(@attrs[:class]) if @attrs[:class]
    end

    private

    def default_attrs
      {}
    end
  end
end
