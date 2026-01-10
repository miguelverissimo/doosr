# ColoredLink Component

## Overview

The `ColoredLink` component is a custom extension of the RubyUI Link component that provides a wide range of color variants, similar to the `BadgeLink` component.

## Location

`app/components/colored_link.rb`

## Usage

```ruby
render Components::ColoredLink.new(href: "/path", variant: :primary, size: :md) do
  "Link Text"
end
```

## Parameters

- `href`: The URL to link to (default: "#")
- `variant`: The color variant (default: `:primary`)
- `size`: The size of the link (default: `:md`)
- `icon`: Boolean, whether this is an icon-only link (default: `false`)
- `plain`: Boolean, render as plain text link without button styling (default: `false`)

## Available Sizes

- `:sm` - Small
- `:md` - Medium (default)
- `:lg` - Large
- `:xl` - Extra Large

## Available Variants

### Base Variants
- `:primary` - Primary theme color
- `:link` - Underlined link style
- `:secondary` - Secondary theme color
- `:destructive` - Red destructive action
- `:outline` - Outlined style
- `:ghost` - No background
- `:success` - Green success color
- `:warning` - Warning color

### Color Variants
- `:red`
- `:orange`
- `:amber`
- `:yellow`
- `:lime`
- `:green`
- `:emerald`
- `:teal`
- `:cyan`
- `:sky`
- `:blue`
- `:indigo`
- `:violet`
- `:purple`
- `:fuchsia`
- `:pink`
- `:rose`

### Neutral Colors
- `:slate`
- `:gray`
- `:zinc`
- `:neutral`
- `:stone`

### Ghost Color Variants (No Background)
Ghost variants display colored text with no background, only showing a subtle background on hover.

**Color Variants:**
- `:ghost_red`, `:ghost_orange`, `:ghost_amber`, `:ghost_yellow`
- `:ghost_lime`, `:ghost_green`, `:ghost_emerald`, `:ghost_teal`
- `:ghost_cyan`, `:ghost_sky`, `:ghost_blue`, `:ghost_indigo`
- `:ghost_violet`, `:ghost_purple`, `:ghost_fuchsia`, `:ghost_pink`, `:ghost_rose`

**Neutral Variants:**
- `:ghost_slate`, `:ghost_gray`, `:ghost_zinc`, `:ghost_neutral`, `:ghost_stone`

**Semantic Variants:**
- `:ghost_success`, `:ghost_warning`, `:ghost_destructive`

## Examples

### Basic Usage

```ruby
# Primary link
render Components::ColoredLink.new(href: "/home", variant: :primary) { "Home" }

# Secondary link
render Components::ColoredLink.new(href: "/about", variant: :secondary) { "About" }

# Destructive link
render Components::ColoredLink.new(href: "/delete", variant: :destructive) { "Delete" }
```

### Different Sizes

```ruby
# Small link
render Components::ColoredLink.new(href: "/", variant: :primary, size: :sm) { "Small" }

# Large link
render Components::ColoredLink.new(href: "/", variant: :primary, size: :lg) { "Large" }

# Extra large link
render Components::ColoredLink.new(href: "/", variant: :primary, size: :xl) { "Extra Large" }
```

### Color Variants

```ruby
# Green success link
render Components::ColoredLink.new(href: "/success", variant: :green) { "Success" }

# Blue informational link
render Components::ColoredLink.new(href: "/info", variant: :blue) { "Information" }

# Red error link
render Components::ColoredLink.new(href: "/error", variant: :red) { "Error" }
```

### Ghost Color Variants

Ghost variants are perfect for subtle actions or secondary navigation. They show colored text with no background, displaying a light background tint only on hover.

```ruby
# Ghost blue link - subtle and clean
render Components::ColoredLink.new(href: "/details", variant: :ghost_blue) { "View Details" }

# Ghost red link - for warning actions without being too aggressive
render Components::ColoredLink.new(href: "/delete", variant: :ghost_red) { "Delete" }

# Ghost green link - for success actions
render Components::ColoredLink.new(href: "/confirm", variant: :ghost_green) { "Confirm" }

# Ghost semantic variants
render Components::ColoredLink.new(href: "/save", variant: :ghost_success) { "Save Draft" }
render Components::ColoredLink.new(href: "/warn", variant: :ghost_warning) { "Review Changes" }
render Components::ColoredLink.new(href: "/remove", variant: :ghost_destructive) { "Remove" }
```

### Comparison: Solid vs Ghost

```ruby
# Primary action - use solid variant
render Components::ColoredLink.new(href: "/submit", variant: :blue) { "Submit Form" }

# Secondary action - use ghost variant
render Components::ColoredLink.new(href: "/cancel", variant: :ghost_blue) { "Cancel" }

# Danger action - use solid variant
render Components::ColoredLink.new(href: "/delete", variant: :red) { "Delete Account" }

# Subtle danger action - use ghost variant
render Components::ColoredLink.new(href: "/remove", variant: :ghost_red) { "Remove Item" }
```

### Icon Mode

```ruby
# Icon-only link
render Components::ColoredLink.new(href: "/settings", variant: :ghost, icon: true) do
  render ::Components::Icon::Settings.new(size: "16")
end
```

### Plain Mode (Text-Only Links)

Plain mode renders the link as clickable text without any button styling - perfect for inline links.

```ruby
# Plain text link - no padding, no background
p do
  plain "Read more about "
  render Components::ColoredLink.new(href: "/features", variant: :blue, plain: true) do
    "our features"
  end
  plain " and "
  render Components::ColoredLink.new(href: "/pricing", variant: :blue, plain: true) do
    "pricing"
  end
  plain "."
end

# Status indicator with plain links
div do
  render Components::ColoredLink.new(href: "/active", variant: :success, plain: true) do
    "✓ Active"
  end
  plain " | "
  render Components::ColoredLink.new(href: "/pending", variant: :warning, plain: true) do
    "⏱ Pending"
  end
end
```

See [`colored_link_plain_mode.md`](./colored_link_plain_mode.md) for detailed documentation on plain mode.

## Features

- **Hover Effects**: All variants include smooth hover transitions with darkened colors
- **Focus States**: Proper focus-visible styling for accessibility
- **Disabled States**: Support for disabled and aria-disabled states
- **Responsive**: Works well on all screen sizes
- **Accessible**: Includes proper ARIA attributes and keyboard navigation support

## Comparison with BadgeLink

While `BadgeLink` is designed for badge-style navigation elements with active/inactive states, `ColoredLink` is designed for traditional button-style links with solid backgrounds and hover effects. Use:

- **ColoredLink (Solid variants)**: For button-style action links with solid backgrounds
- **ColoredLink (Ghost variants)**: For subtle button-style links with colored text and light hover effects
- **ColoredLink (Plain mode)**: For text-only inline links without any button styling
- **BadgeLink**: For filter/navigation badges with active/inactive states

## When to Use Each Mode

### Solid Variants
**Use when:**
- The action is primary or important
- You want to draw attention to the link
- The action requires visual emphasis
- Creating standalone call-to-action buttons

### Ghost Variants
**Use when:**
- The action is secondary or optional
- You want a subtle, less prominent link
- Space is limited and you need a lighter visual weight
- Creating button-like elements without heavy styling

### Plain Mode
**Use when:**
- The link should appear as regular text
- Creating inline links within paragraphs
- Building minimalist interfaces
- Adding links to metadata or auxiliary information
- The link should not look like a button at all

## Browser Compatibility

Tested and working in all modern browsers with Tailwind CSS support.

