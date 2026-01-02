# ColoredLink Plain Mode

## Overview

The `plain: true` parameter renders the link as a plain clickable text without any button styling. This is perfect for inline links within paragraphs or when you need a minimal, text-only appearance.

## What is Plain Mode?

Plain mode strips away all button-like styling:
- ❌ No padding
- ❌ No background
- ❌ No rounded corners
- ❌ No shadow or border
- ✅ Just colored text
- ✅ Hover color change
- ✅ Smooth transition

## Usage

### Basic Usage

```ruby
# Plain text link
render Components::ColoredLink.new(href: "/page", variant: :blue, plain: true) do
  "Click here"
end
```

### Inline Usage in Paragraphs

```ruby
p do
  plain "This is a paragraph with "
  render Components::ColoredLink.new(href: "/link", variant: :blue, plain: true) do
    "a blue link"
  end
  plain " that flows naturally with the text."
end
```

### Contextual Actions

```ruby
div do
  plain "Status: "
  render Components::ColoredLink.new(href: "/success", variant: :success, plain: true) do
    "Completed"
  end
  plain " | "
  render Components::ColoredLink.new(href: "/pending", variant: :warning, plain: true) do
    "Pending"
  end
  plain " | "
  render Components::ColoredLink.new(href: "/failed", variant: :destructive, plain: true) do
    "Failed"
  end
end
```

## Comparison: Three Modes

The `ColoredLink` component now has three distinct modes:

### 1. Solid (Default)
Button-style link with solid background.

```ruby
render Components::ColoredLink.new(href: "/action", variant: :blue) do
  "Solid Button"
end
```

**Appearance:**
- Full background color
- White text
- Shadow
- Padding
- Rounded corners

### 2. Ghost
Subtle button with colored text and light background on hover.

```ruby
render Components::ColoredLink.new(href: "/action", variant: :ghost_blue) do
  "Ghost Button"
end
```

**Appearance:**
- Colored text (no background)
- Light background on hover (10% opacity)
- Padding
- Rounded corners

### 3. Plain (New!)
Pure text link with no button styling.

```ruby
render Components::ColoredLink.new(href: "/action", variant: :blue, plain: true) do
  "Plain Link"
end
```

**Appearance:**
- Colored text only
- Darker text on hover
- No padding
- No background
- No borders or shadows

## When to Use Plain Mode

### ✅ Use Plain Mode For:

1. **Inline Links in Content**
   ```ruby
   p do
     plain "Learn more about our "
     render Components::ColoredLink.new(href: "/features", variant: :blue, plain: true) do
       "features"
     end
     plain " and "
     render Components::ColoredLink.new(href: "/pricing", variant: :blue, plain: true) do
       "pricing"
     end
     plain "."
   end
   ```

2. **Text-Heavy Interfaces**
   - Documentation pages
   - Blog posts
   - Help text
   - Footnotes

3. **Minimal UI Components**
   - Breadcrumbs
   - Metadata links
   - Auxiliary navigation

4. **Status Indicators**
   ```ruby
   div(class: "flex gap-2 text-sm") do
     render Components::ColoredLink.new(href: "#", variant: :green, plain: true) do
       "✓ Approved"
     end
     render Components::ColoredLink.new(href: "#", variant: :yellow, plain: true) do
       "⏱ Pending"
     end
     render Components::ColoredLink.new(href: "#", variant: :red, plain: true) do
       "✗ Rejected"
     end
   end
   ```

### ❌ Don't Use Plain Mode For:

- Primary call-to-action buttons
- Standalone action buttons
- Form submit buttons
- Navigation menus requiring clear visual separation

## Available Colors in Plain Mode

All color variants work in plain mode:

**Semantic Colors:**
- `:primary`, `:secondary`, `:success`, `:warning`, `:destructive`

**Color Palette:**
- `:red`, `:orange`, `:amber`, `:yellow`, `:lime`, `:green`, `:emerald`
- `:teal`, `:cyan`, `:sky`, `:blue`, `:indigo`, `:violet`, `:purple`
- `:fuchsia`, `:pink`, `:rose`

**Neutrals:**
- `:slate`, `:gray`, `:zinc`, `:neutral`, `:stone`

**Ghost Variants:**
- All `:ghost_*` variants also work in plain mode

## Styling Details

### Default State
```css
text-[color]-500
transition-colors
```

### Hover State
```css
text-[color]-600  /* Slightly darker */
```

### Focus State
- Includes focus ring for accessibility
- Keyboard navigation support

## Real-World Examples

### Example 1: Documentation Links

```ruby
div(class: "prose") do
  h2 { "Getting Started" }
  p do
    plain "Before you begin, make sure you've read the "
    render Components::ColoredLink.new(href: "/docs/installation", variant: :blue, plain: true) do
      "installation guide"
    end
    plain " and "
    render Components::ColoredLink.new(href: "/docs/config", variant: :blue, plain: true) do
      "configuration documentation"
    end
    plain "."
  end
end
```

### Example 2: Card Footer Links

```ruby
div(class: "card") do
  h3 { "Product Name" }
  p { "Description..." }
  
  div(class: "mt-4 flex gap-4 text-sm") do
    render Components::ColoredLink.new(href: "/details", variant: :blue, plain: true) do
      "View Details →"
    end
    render Components::ColoredLink.new(href: "/compare", variant: :gray, plain: true) do
      "Compare"
    end
  end
end
```

### Example 3: Status Updates

```ruby
div(class: "space-y-2") do
  div do
    span(class: "text-muted-foreground") { "Status: " }
    render Components::ColoredLink.new(href: "/status", variant: :success, plain: true) do
      "Active"
    end
  end
  
  div do
    span(class: "text-muted-foreground") { "Last updated: " }
    render Components::ColoredLink.new(href: "/history", variant: :blue, plain: true) do
      "2 hours ago"
    end
  end
end
```

### Example 4: Breadcrumbs

```ruby
nav(class: "flex items-center gap-2 text-sm") do
  render Components::ColoredLink.new(href: "/", variant: :gray, plain: true) do
    "Home"
  end
  span(class: "text-muted-foreground") { "/" }
  render Components::ColoredLink.new(href: "/products", variant: :gray, plain: true) do
    "Products"
  end
  span(class: "text-muted-foreground") { "/" }
  span(class: "text-foreground") { "Current Page" }
end
```

## Accessibility

Plain mode maintains all accessibility features:
- ✅ Keyboard navigation
- ✅ Focus indicators
- ✅ Screen reader support
- ✅ Sufficient color contrast
- ✅ Disabled state support

## Browser Testing

Tested and verified:
- ✅ All colors render correctly
- ✅ Hover states work smoothly
- ✅ No unwanted padding or backgrounds
- ✅ Text flows naturally inline
- ✅ Transitions are smooth

## Implementation Notes

The `plain: true` parameter:
- Uses `PLAIN_CLASSES` instead of `BASE_CLASSES`
- Removes all size-based padding
- Applies simple text color classes
- Maintains transition effects
- Preserves accessibility features

