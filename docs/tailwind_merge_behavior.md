# Tailwind Merge Behavior in RubyUI Components

## The Issue

When adding Tailwind classes to RubyUI components, some classes may appear to be ignored. This is due to the `tailwind_merge` gem used in `RubyUI::Base`.

## How It Works

1. **RubyUI components** (Button, Dialog, Input, etc.) inherit from `RubyUI::Base`
2. `RubyUI::Base` uses `tailwind_merge` to intelligently merge classes
3. **Conflicting classes** are automatically resolved - only one is kept
4. **Order matters**: The last class in the merged array typically wins

## Example: Conflicting Whitespace Classes

```ruby
# Button has default: "whitespace-nowrap"
Button(variant: :primary, class: "whitespace-pre-line")
# Result: "whitespace-pre-line" (user class wins because it comes last)
```

## Class Merge Order

In `RubyUI::Base.initialize`:
```ruby
[default_val, user_val].flatten.compact
```

User classes come **after** default classes, so they should win in conflicts.

## When Classes Get Ignored

1. **Conflicting utility classes**: `whitespace-nowrap` vs `whitespace-pre-line`
2. **Conflicting color classes**: `bg-primary` vs `bg-red-500`
3. **Conflicting size classes**: `text-sm` vs `text-lg`

## Solutions

### 1. Use Inline Styles (Most Reliable)
For properties that might conflict, use inline styles:
```ruby
div(class: "text-sm", style: "white-space: pre-line;") { content }
```

### 2. Be Aware of Default Classes
Check the component's default classes before adding conflicting ones:
- Button: `whitespace-nowrap` in BASE_CLASSES
- Other components may have similar defaults

### 3. Regular Phlex Elements
Regular `div`, `span`, etc. in views **don't** go through `tailwind_merge`:
- `Views::Base` < `Components::Base` < `Phlex::HTML`
- Only RubyUI components use `tailwind_merge`
- Regular divs should work as expected

### 4. Override Component Defaults
If you need to change a default class, you may need to:
- Create a custom component variant
- Use inline styles
- Modify the component's default classes

## Testing Class Merging

You can test how classes merge:
```ruby
rails runner "require 'tailwind_merge'; merger = TailwindMerge::Merger.new; puts merger.merge(['whitespace-nowrap', 'whitespace-pre-line'])"
```

## Best Practices

1. **For RubyUI components**: Check default classes, use inline styles for overrides
2. **For regular divs**: Tailwind classes work normally (no merge processing)
3. **When in doubt**: Use inline styles for CSS properties that might conflict

