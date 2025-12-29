# frozen_string_literal: true

module RubyUI
  class Button < Base
    BASE_CLASSES = [
      "whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors",
      "disabled:pointer-events-none disabled:opacity-50",
      "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
      "aria-disabled:pointer-events-none aria-disabled:opacity-50 aria-disabled:cursor-not-allowed"
    ].freeze

    TINT_COLORS = {
      red: "red",
      orange: "orange",
      amber: "amber",
      yellow: "yellow",
      lime: "lime",
      green: "green",
      emerald: "emerald",
      teal: "teal",
      cyan: "cyan",
      sky: "sky",
      blue: "blue",
      indigo: "indigo",
      violet: "violet",
      purple: "purple",
      fuchsia: "fuchsia",
      pink: "pink",
      rose: "rose"
    }.freeze

    def initialize(type: :button, variant: :primary, size: :md, icon: false, tint: nil, **attrs)
      @type = type
      @variant = variant.to_sym
      @size = size.to_sym
      @icon = icon
      @tint = tint&.to_sym
      super(**attrs)
    end

    def view_template(&)
      if attrs[:href]
        a(**attrs.except(:type), &)
      else
        button(**attrs, &)
      end
    end

    private

    def size_classes
      if @icon
        case @size
        when :sm then "h-6 w-6"
        when :md then "h-9 w-9"
        when :lg then "h-10 w-10"
        when :xl then "h-12 w-12"
        end
      else
        case @size
        when :sm then "px-3 py-1.5 h-8 text-xs"
        when :md then "px-4 py-2 h-9 text-sm"
        when :lg then "px-4 py-2 h-10 text-base"
        when :xl then "px-6 py-3 h-12 text-base"
        end
      end
    end

    def primary_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-primary text-primary-foreground shadow",
        "hover:bg-primary/90"
      ]
    end

    def link_classes
      [
        BASE_CLASSES,
        size_classes,
        "text-primary underline-offset-4",
        "hover:underline"
      ]
    end

    def secondary_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-secondary text-secondary-foreground",
        "hover:bg-opacity-80"
      ]
    end

    def destructive_classes
      [
        BASE_CLASSES,
        size_classes,
        "bg-destructive text-white shadow-sm",
        "[a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20",
        "dark:focus-visible:ring-destructive/40 dark:bg-destructive/60"
      ]
    end

    def outline_classes
      [
        BASE_CLASSES,
        size_classes,
        "border border-input bg-background shadow-sm",
        "hover:bg-accent hover:text-accent-foreground"
      ]
    end

    def ghost_classes
      [
        BASE_CLASSES,
        size_classes,
        "hover:bg-accent hover:text-accent-foreground"
      ]
    end

    def tinted_base_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors",
        "disabled:pointer-events-none disabled:opacity-50",
        "focus-visible:outline-none focus-visible:ring-1",
        "aria-disabled:pointer-events-none aria-disabled:opacity-50 aria-disabled:cursor-not-allowed"
      ]
    end

    def tinted_classes
      if @tint && TINT_COLORS[@tint]
        [
          tinted_base_classes,
          size_classes,
          tinted_color_classes(@tint)
        ]
      else
        [
          BASE_CLASSES,
          size_classes,
          "border border-input bg-background shadow-sm",
          "hover:bg-accent hover:text-accent-foreground"
        ]
      end
    end

    def tinted_color_classes(tint)
      case tint
      when :red
        [ "border border-red-500/20 bg-red-500/10 text-red-500 shadow-sm ring-red-500/20", "hover:bg-red-500/50 hover:text-white", "focus-visible:ring-red-500/20" ]
      when :orange
        [ "border border-orange-500/20 bg-orange-500/10 text-orange-500 shadow-sm ring-orange-500/20", "hover:bg-orange-500/50 hover:text-white", "focus-visible:ring-orange-500/20" ]
      when :amber
        [ "border border-amber-500/20 bg-amber-500/10 text-amber-500 shadow-sm ring-amber-500/20", "hover:bg-amber-500/50 hover:text-white", "focus-visible:ring-amber-500/20" ]
      when :yellow
        [ "border border-yellow-500/20 bg-yellow-500/10 text-yellow-500 shadow-sm ring-yellow-500/20", "hover:bg-yellow-500/50 hover:text-white", "focus-visible:ring-yellow-500/20" ]
      when :lime
        [ "border border-lime-500/20 bg-lime-500/10 text-lime-500 shadow-sm ring-lime-500/20", "hover:bg-lime-500/50 hover:text-white", "focus-visible:ring-lime-500/20" ]
      when :green
        [ "border border-green-500/20 bg-green-500/10 text-green-500 shadow-sm ring-green-500/20", "hover:bg-green-500/50 hover:text-white", "focus-visible:ring-green-500/20" ]
      when :emerald
        [ "border border-emerald-500/20 bg-emerald-500/10 text-emerald-500 shadow-sm ring-emerald-500/20", "hover:bg-emerald-500/50 hover:text-white", "focus-visible:ring-emerald-500/20" ]
      when :teal
        [ "border border-teal-500/20 bg-teal-500/10 text-teal-500 shadow-sm ring-teal-500/20", "hover:bg-teal-500/50 hover:text-white", "focus-visible:ring-teal-500/20" ]
      when :cyan
        [ "border border-cyan-500/20 bg-cyan-500/10 text-cyan-500 shadow-sm ring-cyan-500/20", "hover:bg-cyan-500/50 hover:text-white", "focus-visible:ring-cyan-500/20" ]
      when :sky
        [ "border border-sky-500/20 bg-sky-500/10 text-sky-500 shadow-sm ring-sky-500/20", "hover:bg-sky-500/50 hover:text-white", "focus-visible:ring-sky-500/20" ]
      when :blue
        [ "border border-blue-500/20 bg-blue-500/10 text-blue-500 shadow-sm ring-blue-500/20", "hover:bg-blue-500/50 hover:text-white", "focus-visible:ring-blue-500/20" ]
      when :indigo
        [ "border border-indigo-500/20 bg-indigo-500/10 text-indigo-500 shadow-sm ring-indigo-500/20", "hover:bg-indigo-500/50 hover:text-white", "focus-visible:ring-indigo-500/20" ]
      when :violet
        [ "border border-violet-500/20 bg-violet-500/10 text-violet-500 shadow-sm ring-violet-500/20", "hover:bg-violet-500/50 hover:text-white", "focus-visible:ring-violet-500/20" ]
      when :purple
        [ "border border-purple-500/20 bg-purple-500/10 text-purple-500 shadow-sm ring-purple-500/20", "hover:bg-purple-500/50 hover:text-white", "focus-visible:ring-purple-500/20" ]
      when :fuchsia
        [ "border border-fuchsia-500/20 bg-fuchsia-500/10 text-fuchsia-500 shadow-sm ring-fuchsia-500/20", "hover:bg-fuchsia-500/50 hover:text-white", "focus-visible:ring-fuchsia-500/20" ]
      when :pink
        [ "border border-pink-500/20 bg-pink-500/10 text-pink-500 shadow-sm ring-pink-500/20", "hover:bg-pink-500/50 hover:text-white", "focus-visible:ring-pink-500/20" ]
      when :rose
        [ "border border-rose-500/20 bg-rose-500/10 text-rose-500 shadow-sm ring-rose-500/20", "hover:bg-rose-500/50 hover:text-white", "focus-visible:ring-rose-500/20" ]
      end
    end

    def default_classes
      case @variant
      when :primary then primary_classes
      when :link then link_classes
      when :secondary then secondary_classes
      when :destructive then destructive_classes
      when :outline then outline_classes
      when :ghost then ghost_classes
      when :tinted then tinted_classes
      end
    end

    def default_attrs
      { type: @type, class: default_classes }
    end
  end
end
