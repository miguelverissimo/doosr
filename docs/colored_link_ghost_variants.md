# ColoredLink Ghost Variants

## Overview

Ghost variants provide a subtle, clean appearance with colored text and no background. They display a light background tint (10% opacity) only on hover, making them perfect for secondary actions or inline links.

## What Was Added

Extended the `ColoredLink` component with 28 new ghost color variants:

### Color Ghost Variants (17)
- `:ghost_red`, `:ghost_orange`, `:ghost_amber`, `:ghost_yellow`
- `:ghost_lime`, `:ghost_green`, `:ghost_emerald`, `:ghost_teal`
- `:ghost_cyan`, `:ghost_sky`, `:ghost_blue`, `:ghost_indigo`
- `:ghost_violet`, `:ghost_purple`, `:ghost_fuchsia`, `:ghost_pink`, `:ghost_rose`

### Neutral Ghost Variants (5)
- `:ghost_slate`, `:ghost_gray`, `:ghost_zinc`, `:ghost_neutral`, `:ghost_stone`

### Semantic Ghost Variants (3)
- `:ghost_success`, `:ghost_warning`, `:ghost_destructive`

## Visual Design

**Default State:**
- Colored text (500 shade)
- No background
- No shadow or border

**Hover State:**
- Slightly darker text (600 shade for most colors)
- Light background tint (10% opacity of the color)
- Smooth transition

## Usage Examples

### Basic Usage

```ruby
# Ghost blue link
render Components::ColoredLink.new(href: "/details", variant: :ghost_blue) do
  "View Details"
end

# Ghost red link (subtle warning)
render Components::ColoredLink.new(href: "/delete", variant: :ghost_red) do
  "Delete"
end

# Ghost success link
render Components::ColoredLink.new(href: "/save", variant: :ghost_success) do
  "Save Draft"
end
```

### Use Cases

#### 1. Secondary Actions in Cards

```ruby
div(class: "card") do
  h3 { "Product Name" }
  p { "Product description..." }
  
  div(class: "flex gap-2") do
    # Primary action - solid variant
    render Components::ColoredLink.new(href: "/buy", variant: :blue) do
      "Buy Now"
    end
    
    # Secondary action - ghost variant
    render Components::ColoredLink.new(href: "/details", variant: :ghost_blue) do
      "Learn More"
    end
  end
end
```

#### 2. Inline Links in Text

```ruby
p(class: "text-muted-foreground") do
  plain "Need help? "
  render Components::ColoredLink.new(href: "/support", variant: :ghost_blue, size: :sm) do
    "Contact Support"
  end
  plain " or "
  render Components::ColoredLink.new(href: "/docs", variant: :ghost_blue, size: :sm) do
    "Read Documentation"
  end
end
```

#### 3. Action Lists

```ruby
div(class: "space-y-2") do
  render Components::ColoredLink.new(href: "/edit", variant: :ghost_blue) do
    "Edit Profile"
  end
  render Components::ColoredLink.new(href: "/settings", variant: :ghost_gray) do
    "Settings"
  end
  render Components::ColoredLink.new(href: "/delete", variant: :ghost_red) do
    "Delete Account"
  end
end
```

#### 4. Navigation with Color Coding

```ruby
div(class: "flex gap-2") do
  # Status indicators
  render Components::ColoredLink.new(href: "/pending", variant: :ghost_yellow) do
    "Pending (5)"
  end
  render Components::ColoredLink.new(href: "/approved", variant: :ghost_green) do
    "Approved (12)"
  end
  render Components::ColoredLink.new(href: "/rejected", variant: :ghost_red) do
    "Rejected (2)"
  end
end
```

## Design Guidelines

### When to Use Ghost Variants

✅ **Use ghost variants for:**
- Secondary or optional actions
- Inline links within content
- Action lists where visual weight should be minimal
- Cancel/close actions
- Navigation items in tight spaces
- Actions that should be present but not prominent

### When NOT to Use Ghost Variants

❌ **Don't use ghost variants for:**
- Primary call-to-action buttons
- Important actions that need emphasis
- Standalone buttons that need to stand out
- First action in a form or workflow

### Color Selection Guide

**Blue/Sky/Indigo**: General actions, information, navigation
**Green/Emerald/Teal**: Success states, positive actions
**Red/Rose**: Delete, remove, cancel, dangerous actions
**Yellow/Amber**: Warning states, attention needed
**Purple/Violet**: Premium features, special actions
**Gray/Slate**: Neutral actions, secondary navigation

## Accessibility

All ghost variants maintain good contrast ratios:
- Text color uses 500 shade (sufficient contrast)
- Hover state uses 600 shade (enhanced contrast)
- Focus states include ring indicators for keyboard navigation

## Browser Testing

Tested and verified in the browser at `/fixed_calendar` with all variants displaying correctly:
- Colors render accurately
- Hover effects work smoothly
- Text remains readable
- Transitions are smooth

## Implementation Details

Each ghost variant follows this pattern:

```ruby
when :ghost_[color]
  "text-[color]-500 hover:bg-[color]-500/10 hover:text-[color]-600"
```

Semantic variants use theme colors:

```ruby
when :ghost_success
  "text-success hover:bg-success/10"
```

This ensures consistency across the design system while providing flexibility for different use cases.

