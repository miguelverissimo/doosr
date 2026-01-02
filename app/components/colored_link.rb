# frozen_string_literal: true

class ::Components::ColoredLink < ::Components::Base
  BASE_CLASSES = [
    "whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors cursor-pointer",
    "disabled:pointer-events-none disabled:opacity-50",
    "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
    "aria-disabled:pointer-events-none aria-disabled:opacity-50 aria-disabled:cursor-not-allowed"
  ].freeze

  PLAIN_CLASSES = [
    "inline-flex items-center transition-colors cursor-pointer",
    "disabled:pointer-events-none disabled:opacity-50",
    "focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
    "aria-disabled:pointer-events-none aria-disabled:opacity-50 aria-disabled:cursor-not-allowed"
  ].freeze

  def initialize(href: "#", variant: :primary, size: :md, icon: false, plain: false, **user_attrs)
    @href = href
    @variant = variant
    @size = size
    @icon = icon
    @plain = plain
    super(**user_attrs)
  end

  def view_template(&block)
    a(**link_attrs, &block)
  end

  private

  def link_attrs
    {
      href: @href,
      class: [
        @plain ? PLAIN_CLASSES : BASE_CLASSES,
        size_classes,
        variant_classes,
        @attrs[:class]
      ]
    }.merge(@attrs.except(:class))
  end

  def size_classes
    return "" if @plain

    if @icon
      case @size
      when :sm then "h-6 w-6"
      when :md then "h-9 w-9"
      when :lg then "h-10 w-10"
      when :xl then "h-12 w-12"
      else "h-9 w-9"
      end
    else
      case @size
      when :sm then "px-3 py-1.5 h-8 text-xs"
      when :md then "px-4 py-2 h-9 text-sm"
      when :lg then "px-4 py-2 h-10 text-base"
      when :xl then "px-6 py-3 h-12 text-base"
      else "px-4 py-2 h-9 text-sm"
      end
    end
  end

  def variant_classes
    return plain_variant_classes if @plain

    case @variant
    when :primary
      "bg-primary text-primary-foreground shadow hover:bg-primary/90"
    when :link
      "text-primary underline-offset-4 hover:underline"
    when :secondary
      "bg-secondary text-secondary-foreground hover:bg-opacity-80"
    when :destructive
      "bg-destructive text-white shadow-sm hover:bg-destructive/90 focus-visible:ring-destructive/20"
    when :outline
      "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground"
    when :ghost
      "hover:bg-accent hover:text-accent-foreground"
    when :success
      "bg-success text-white shadow hover:bg-success/90"
    when :warning
      "bg-warning text-white shadow hover:bg-warning/90"
    # Ghost variants with colors (no background, colored text)
    when :ghost_slate
      "text-slate-500 hover:bg-slate-500/10 hover:text-slate-600"
    when :ghost_gray
      "text-gray-500 hover:bg-gray-500/10 hover:text-gray-600"
    when :ghost_zinc
      "text-zinc-500 hover:bg-zinc-500/10 hover:text-zinc-600"
    when :ghost_neutral
      "text-neutral-500 hover:bg-neutral-500/10 hover:text-neutral-600"
    when :ghost_stone
      "text-stone-500 hover:bg-stone-500/10 hover:text-stone-600"
    when :ghost_red
      "text-red-500 hover:bg-red-500/10 hover:text-red-600"
    when :ghost_orange
      "text-orange-500 hover:bg-orange-500/10 hover:text-orange-600"
    when :ghost_amber
      "text-amber-500 hover:bg-amber-500/10 hover:text-amber-600"
    when :ghost_yellow
      "text-yellow-500 hover:bg-yellow-500/10 hover:text-yellow-600"
    when :ghost_lime
      "text-lime-500 hover:bg-lime-500/10 hover:text-lime-600"
    when :ghost_green
      "text-green-500 hover:bg-green-500/10 hover:text-green-600"
    when :ghost_emerald
      "text-emerald-500 hover:bg-emerald-500/10 hover:text-emerald-600"
    when :ghost_teal
      "text-teal-500 hover:bg-teal-500/10 hover:text-teal-600"
    when :ghost_cyan
      "text-cyan-500 hover:bg-cyan-500/10 hover:text-cyan-600"
    when :ghost_sky
      "text-sky-500 hover:bg-sky-500/10 hover:text-sky-600"
    when :ghost_blue
      "text-blue-500 hover:bg-blue-500/10 hover:text-blue-600"
    when :ghost_indigo
      "text-indigo-500 hover:bg-indigo-500/10 hover:text-indigo-600"
    when :ghost_violet
      "text-violet-500 hover:bg-violet-500/10 hover:text-violet-600"
    when :ghost_purple
      "text-purple-500 hover:bg-purple-500/10 hover:text-purple-600"
    when :ghost_fuchsia
      "text-fuchsia-500 hover:bg-fuchsia-500/10 hover:text-fuchsia-600"
    when :ghost_pink
      "text-pink-500 hover:bg-pink-500/10 hover:text-pink-600"
    when :ghost_rose
      "text-rose-500 hover:bg-rose-500/10 hover:text-rose-600"
    when :ghost_success
      "text-success hover:bg-success/10"
    when :ghost_warning
      "text-warning hover:bg-warning/10"
    when :ghost_destructive
      "text-destructive hover:bg-destructive/10"
    when :slate
      "bg-slate-500 text-white shadow hover:bg-slate-500/90"
    when :gray
      "bg-gray-500 text-white shadow hover:bg-gray-500/90"
    when :zinc
      "bg-zinc-500 text-white shadow hover:bg-zinc-500/90"
    when :neutral
      "bg-neutral-500 text-white shadow hover:bg-neutral-500/90"
    when :stone
      "bg-stone-500 text-white shadow hover:bg-stone-500/90"
    when :red
      "bg-red-500 text-white shadow hover:bg-red-500/90"
    when :orange
      "bg-orange-500 text-white shadow hover:bg-orange-500/90"
    when :amber
      "bg-amber-500 text-white shadow hover:bg-amber-500/90"
    when :yellow
      "bg-yellow-500 text-white shadow hover:bg-yellow-500/90"
    when :lime
      "bg-lime-500 text-white shadow hover:bg-lime-500/90"
    when :green
      "bg-green-500 text-white shadow hover:bg-green-500/90"
    when :emerald
      "bg-emerald-500 text-white shadow hover:bg-emerald-500/90"
    when :teal
      "bg-teal-500 text-white shadow hover:bg-teal-500/90"
    when :cyan
      "bg-cyan-500 text-white shadow hover:bg-cyan-500/90"
    when :sky
      "bg-sky-500 text-white shadow hover:bg-sky-500/90"
    when :blue
      "bg-blue-500 text-white shadow hover:bg-blue-500/90"
    when :indigo
      "bg-indigo-500 text-white shadow hover:bg-indigo-500/90"
    when :violet
      "bg-violet-500 text-white shadow hover:bg-violet-500/90"
    when :purple
      "bg-purple-500 text-white shadow hover:bg-purple-500/90"
    when :fuchsia
      "bg-fuchsia-500 text-white shadow hover:bg-fuchsia-500/90"
    when :pink
      "bg-pink-500 text-white shadow hover:bg-pink-500/90"
    when :rose
      "bg-rose-500 text-white shadow hover:bg-rose-500/90"
    else
      "bg-primary text-primary-foreground shadow hover:bg-primary/90"
    end
  end

  def plain_variant_classes
    case @variant
    when :primary
      "text-primary hover:text-primary/80"
    when :link
      "text-primary hover:text-primary/80"
    when :secondary
      "text-secondary hover:text-secondary/80"
    when :destructive
      "text-destructive hover:text-destructive/80"
    when :outline
      "text-foreground hover:text-foreground/80"
    when :ghost
      "text-foreground hover:text-foreground/80"
    when :success
      "text-success hover:text-success/80"
    when :warning
      "text-warning hover:text-warning/80"
    # Plain ghost variants (same as ghost color but simpler)
    when :ghost_slate
      "text-slate-500 hover:text-slate-600"
    when :ghost_gray
      "text-gray-500 hover:text-gray-600"
    when :ghost_zinc
      "text-zinc-500 hover:text-zinc-600"
    when :ghost_neutral
      "text-neutral-500 hover:text-neutral-600"
    when :ghost_stone
      "text-stone-500 hover:text-stone-600"
    when :ghost_red
      "text-red-500 hover:text-red-600"
    when :ghost_orange
      "text-orange-500 hover:text-orange-600"
    when :ghost_amber
      "text-amber-500 hover:text-amber-600"
    when :ghost_yellow
      "text-yellow-500 hover:text-yellow-600"
    when :ghost_lime
      "text-lime-500 hover:text-lime-600"
    when :ghost_green
      "text-green-500 hover:text-green-600"
    when :ghost_emerald
      "text-emerald-500 hover:text-emerald-600"
    when :ghost_teal
      "text-teal-500 hover:text-teal-600"
    when :ghost_cyan
      "text-cyan-500 hover:text-cyan-600"
    when :ghost_sky
      "text-sky-500 hover:text-sky-600"
    when :ghost_blue
      "text-blue-500 hover:text-blue-600"
    when :ghost_indigo
      "text-indigo-500 hover:text-indigo-600"
    when :ghost_violet
      "text-violet-500 hover:text-violet-600"
    when :ghost_purple
      "text-purple-500 hover:text-purple-600"
    when :ghost_fuchsia
      "text-fuchsia-500 hover:text-fuchsia-600"
    when :ghost_pink
      "text-pink-500 hover:text-pink-600"
    when :ghost_rose
      "text-rose-500 hover:text-rose-600"
    when :ghost_success
      "text-success hover:text-success/80"
    when :ghost_warning
      "text-warning hover:text-warning/80"
    when :ghost_destructive
      "text-destructive hover:text-destructive/80"
    # Plain solid color variants
    when :slate
      "text-slate-500 hover:text-slate-600"
    when :gray
      "text-gray-500 hover:text-gray-600"
    when :zinc
      "text-zinc-500 hover:text-zinc-600"
    when :neutral
      "text-neutral-500 hover:text-neutral-600"
    when :stone
      "text-stone-500 hover:text-stone-600"
    when :red
      "text-red-500 hover:text-red-600"
    when :orange
      "text-orange-500 hover:text-orange-600"
    when :amber
      "text-amber-500 hover:text-amber-600"
    when :yellow
      "text-yellow-500 hover:text-yellow-600"
    when :lime
      "text-lime-500 hover:text-lime-600"
    when :green
      "text-green-500 hover:text-green-600"
    when :emerald
      "text-emerald-500 hover:text-emerald-600"
    when :teal
      "text-teal-500 hover:text-teal-600"
    when :cyan
      "text-cyan-500 hover:text-cyan-600"
    when :sky
      "text-sky-500 hover:text-sky-600"
    when :blue
      "text-blue-500 hover:text-blue-600"
    when :indigo
      "text-indigo-500 hover:text-indigo-600"
    when :violet
      "text-violet-500 hover:text-violet-600"
    when :purple
      "text-purple-500 hover:text-purple-600"
    when :fuchsia
      "text-fuchsia-500 hover:text-fuchsia-600"
    when :pink
      "text-pink-500 hover:text-pink-600"
    when :rose
      "text-rose-500 hover:text-rose-600"
    else
      "text-primary hover:text-primary/80"
    end
  end
end
