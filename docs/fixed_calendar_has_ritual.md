# FixedCalendar::Converter - has_ritual? Method

## Overview

The `has_ritual?` method checks if a given date has a ritual associated with it in the Fixed Calendar system.

## Usage

### Class Method

```ruby
# Check if a specific date has a ritual
date = Date.new(2026, 3, 20) # New Year (Ostara)
FixedCalendar::Converter.has_ritual?(date)
# => true

date = Date.new(2026, 4, 15) # Random day
FixedCalendar::Converter.has_ritual?(date)
# => false
```

### Instance Method

```ruby
converter = FixedCalendar::Converter.new(Date.new(2026, 3, 20))
converter.has_ritual?
# => true

converter = FixedCalendar::Converter.new(Date.new(2026, 4, 15))
converter.has_ritual?
# => false
```

## Ritual Days Detected

The method returns `true` for the following ritual days:

1. **New Year (Ostara)** - March 20 (Martius 1)
2. **Beltane** - May 1 (Aprilis 15)
3. **Solstice (Litha)** - June 21 (Iunius 10)
4. **Lughnasadh** - August 1 (Sol 23)
5. **Autumn Equinox (Mabon)** - September 22 (Augustus 19)
6. **Samhain** - October 31 (October 2)
7. **Winter Solstice (Yule)** - December 21 (varies)
8. **Imbolc** - February 1 (varies)
9. **Year Day** - March 19 (special day)

## Return Values

- Returns `true` if the date has a ritual
- Returns `false` if the date has no ritual
- Leap Day (when present) returns `false`
- Year Day always returns `true`

## Implementation Details

The method:
1. Converts the supplied date to the Fixed Calendar system
2. Checks if the date is Year Day (always has a ritual)
3. Checks if the date is Leap Day (never has a ritual)
4. For regular days, checks if the month/day combination matches any ritual in `RITUAL_DAYS`

## Example: Conditional Rendering

```ruby
# In a view or component
date = Date.current
converter = FixedCalendar::Converter.new(date)

if converter.has_ritual?
  # Show special ritual indicator
  render_ritual_badge(converter)
else
  # Show normal date display
  render_normal_date(converter)
end
```

## Example: Filtering Ritual Days

```ruby
# Find all ritual days in a date range
date_range = (Date.new(2026, 3, 1)..Date.new(2026, 12, 31))
ritual_days = date_range.select { |date| FixedCalendar::Converter.has_ritual?(date) }

puts "Found #{ritual_days.count} ritual days"
ritual_days.each do |date|
  converter = FixedCalendar::Converter.new(date)
  puts "#{date}: #{converter.to_formatted_string}"
end
```

