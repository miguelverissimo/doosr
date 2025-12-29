# frozen_string_literal: true

class ::Components::BadgeLink < ::Components::Base
  def initialize(href:, variant: :primary, size: :md, active: false, **user_attrs)
    @href = href
    @variant = variant
    @size = size
    @active = active
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
        "inline-flex items-center rounded-md font-medium ring-1 ring-inset cursor-pointer",
        size_classes,
        color_classes,
        @attrs[:class]
      ]
    }.merge(@attrs.except(:class))
  end

  def size_classes
    case @size
    when :sm
      "px-1.5 py-0.5 text-xs"
    when :md
      "px-2 py-1 text-xs"
    when :lg
      "px-3 py-1 text-sm"
    else
      "px-2 py-1 text-xs"
    end
  end

  def color_classes
    @active ? active_colors : inactive_colors
  end

  def active_colors
    case @variant
    when :primary
      "text-primary bg-primary/5 ring-primary/20"
    when :secondary
      "text-secondary bg-secondary/10 ring-secondary/20"
    when :outline
      "text-foreground bg-background ring-border"
    when :destructive
      "text-destructive bg-destructive/10 ring-destructive/20"
    when :success
      "text-success bg-success/10 ring-success/20"
    when :warning
      "text-warning bg-warning/10 ring-warning/20"
    when :slate
      "text-slate-500 bg-slate-500/10 ring-slate-500/20"
    when :gray
      "text-gray-500 bg-gray-500/10 ring-gray-500/20"
    when :zinc
      "text-zinc-500 bg-zinc-500/10 ring-zinc-500/20"
    when :neutral
      "text-neutral-500 bg-neutral-500/10 ring-neutral-500/20"
    when :stone
      "text-stone-500 bg-stone-500/10 ring-stone-500/20"
    when :red
      "text-red-500 bg-red-500/10 ring-red-500/20"
    when :orange
      "text-orange-500 bg-orange-500/10 ring-orange-500/20"
    when :amber
      "text-amber-500 bg-amber-500/10 ring-amber-500/20"
    when :yellow
      "text-yellow-500 bg-yellow-500/10 ring-yellow-500/20"
    when :lime
      "text-lime-500 bg-lime-500/10 ring-lime-500/20"
    when :green
      "text-green-500 bg-green-500/10 ring-green-500/20"
    when :emerald
      "text-emerald-500 bg-emerald-500/10 ring-emerald-500/20"
    when :teal
      "text-teal-500 bg-teal-500/10 ring-teal-500/20"
    when :cyan
      "text-cyan-500 bg-cyan-500/10 ring-cyan-500/20"
    when :sky
      "text-sky-500 bg-sky-500/10 ring-sky-500/20"
    when :blue
      "text-blue-500 bg-blue-500/10 ring-blue-500/20"
    when :indigo
      "text-indigo-500 bg-indigo-500/10 ring-indigo-500/20"
    when :violet
      "text-violet-500 bg-violet-500/10 ring-violet-500/20"
    when :purple
      "text-purple-500 bg-purple-500/10 ring-purple-500/20"
    when :fuchsia
      "text-fuchsia-500 bg-fuchsia-500/10 ring-fuchsia-500/20"
    when :pink
      "text-pink-500 bg-pink-500/10 ring-pink-500/20"
    when :rose
      "text-rose-500 bg-rose-500/10 ring-rose-500/20"
    else
      "text-primary bg-primary/5 ring-primary/20"
    end
  end

  def inactive_colors
    case @variant
    when :primary
      "text-primary/50 bg-primary/5 ring-primary/20"
    when :secondary
      "text-secondary/50 bg-secondary/10 ring-secondary/20"
    when :outline
      "text-foreground/50 bg-background ring-border"
    when :destructive
      "text-destructive/50 bg-destructive/10 ring-destructive/20"
    when :success
      "text-success/50 bg-success/10 ring-success/20"
    when :warning
      "text-warning/50 bg-warning/10 ring-warning/20"
    when :slate
      "text-slate-500/50 bg-slate-500/10 ring-slate-500/20"
    when :gray
      "text-gray-500/50 bg-gray-500/10 ring-gray-500/20"
    when :zinc
      "text-zinc-500/50 bg-zinc-500/10 ring-zinc-500/20"
    when :neutral
      "text-neutral-500/50 bg-neutral-500/10 ring-neutral-500/20"
    when :stone
      "text-stone-500/50 bg-stone-500/10 ring-stone-500/20"
    when :red
      "text-red-500/50 bg-red-500/10 ring-red-500/20"
    when :orange
      "text-orange-500/50 bg-orange-500/10 ring-orange-500/20"
    when :amber
      "text-amber-500/50 bg-amber-500/10 ring-amber-500/20"
    when :yellow
      "text-yellow-500/50 bg-yellow-500/10 ring-yellow-500/20"
    when :lime
      "text-lime-500/50 bg-lime-500/10 ring-lime-500/20"
    when :green
      "text-green-500/50 bg-green-500/10 ring-green-500/20"
    when :emerald
      "text-emerald-500/50 bg-emerald-500/10 ring-emerald-500/20"
    when :teal
      "text-teal-500/50 bg-teal-500/10 ring-teal-500/20"
    when :cyan
      "text-cyan-500/50 bg-cyan-500/10 ring-cyan-500/20"
    when :sky
      "text-sky-500/50 bg-sky-500/10 ring-sky-500/20"
    when :blue
      "text-blue-500/50 bg-blue-500/10 ring-blue-500/20"
    when :indigo
      "text-indigo-500/50 bg-indigo-500/10 ring-indigo-500/20"
    when :violet
      "text-violet-500/50 bg-violet-500/10 ring-violet-500/20"
    when :purple
      "text-purple-500/50 bg-purple-500/10 ring-purple-500/20"
    when :fuchsia
      "text-fuchsia-500/50 bg-fuchsia-500/10 ring-fuchsia-500/20"
    when :pink
      "text-pink-500/50 bg-pink-500/10 ring-pink-500/20"
    when :rose
      "text-rose-500/50 bg-rose-500/10 ring-rose-500/20"
    else
      "text-primary/50 bg-primary/5 ring-primary/20"
    end
  end
end
