# frozen_string_literal: true

class ::Components::BadgeWithIcon < ::Components::Base
  def initialize(icon: nil, element: :plain, href: nil, variant: :primary, size: :md, **user_attrs)
    @icon = icon
    @element = element
    @href = href
    @variant = variant
    @size = size
    super(**user_attrs)
  end

  def view_template(&block)
    span(**badge_attrs) do
      render_icon if @icon
      render_element(&block)
    end
  end

  private

  def badge_attrs
    {
      class: [
        "inline-flex items-center rounded-md font-medium ring-1 ring-inset",
        size_classes,
        color_classes,
        @attrs[:class]
      ]
    }.merge(@attrs.except(:class))
  end

  def render_icon
    render ::Components::Icon.new(
      name: @icon,
      size: icon_size,
      class: "shrink-0"
    )
  end

  def render_element(&block)
    case @element
    when :link
      a(href: @href, class: element_classes, &block)
    when :span
      span(class: element_classes, &block)
    else
      # :plain - just render the block content with spacing
      span(class: element_classes, &block)
    end
  end

  def element_classes
    return nil if @icon.nil?
    "ml-1.5"
  end

  def icon_size
    case @size
    when :sm
      "12"
    when :md
      "14"
    when :lg
      "16"
    else
      "14"
    end
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
end
