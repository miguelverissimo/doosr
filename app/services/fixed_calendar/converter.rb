# frozen_string_literal: true

module FixedCalendar
  class Converter
    MONTHS = [
      "Martius", "Aprilis", "Maius", "Iunius", "Sol", "Iulius", "Augustus",
      "September", "October", "November", "December", "Undecember", "Duodecember"
    ].freeze

    DAY_NAMES = [
      "dies Solis",     # Sunday
      "dies Lunae",     # Monday
      "dies Martis",    # Tuesday
      "dies Mercurii",  # Wednesday
      "dies Iovis",     # Thursday
      "dies Veneris",   # Friday
      "dies Saturni"    # Saturday
    ].freeze

    DAYS_PER_MONTH = 28

    RITUAL_DAYS = {
      "new_year" => {
        month: 0, day: 1,
        name: "New Year (Ostara)",
        gregorian: "March 20",
        action: "Lighting \"need-fires\" on hills and cleaning the home to remove \"winter soot\".",
        symbolism: "People decorated eggs (symbols of new life) and planted the first seeds of the season.",
        purpose: "To physically and spiritually signal the end of winter dormancy."
      },
      "beltane" => {
        month: 1, day: 15,
        name: "Beltane",
        gregorian: "May 1",
        action: "Driving livestock between two large bonfires.",
        symbolism: "Fire was a disinfectant and a \"protective shield.\" People danced around the Maypole (a phallic symbol of fertility) and gathered hawthorn blossoms.",
        purpose: "To protect cattle from disease before sending them to summer pastures and to encourage human procreation."
      },
      "solstice" => {
        month: 3, day: 10,
        name: "Solstice (Litha)",
        gregorian: "June 21",
        action: "Staying awake all night to watch the sun rise; rolling flaming wooden wheels down hills into rivers.",
        symbolism: "The sun is at its maximum power but begins its \"death\" toward winter.",
        purpose: "To \"strengthen\" the sun's energy through sympathetic magic (fire) and to harvest medicinal herbs, which were believed to be most potent on this night."
      },
      "lughnasadh" => {
        month: 4, day: 23,
        name: "Lughnasadh",
        gregorian: "Aug 1",
        action: "The \"Trial of the First Grain\". Baking a communal loaf from the first harvested wheat.",
        symbolism: "Large-scale markets, athletic competitions, and handfastings (temporary marriages).",
        purpose: "To secure the harvest and ensure the community had enough labor for the upcoming intense reaping period."
      },
      "autumn_equinox" => {
        month: 6, day: 19,
        name: "Autumn Equinox (Mabon)",
        gregorian: "Sept 22",
        action: "Massive communal feasts. Bringing in the final fruits and vegetables.",
        symbolism: "Acknowledging the balance of day and night while preparing for the dark.",
        purpose: "Food preservation. This was the time for drying, pickling, and storing goods to survive the winter."
      },
      "samhain" => {
        month: 8, day: 2,
        name: "Samhain",
        gregorian: "Oct 31",
        action: "Culling livestock (killing animals that wouldn't survive winter) and leaving \"dumb suppers\" (empty chairs/plates) for the dead.",
        symbolism: "The boundary between the living and the dead was considered \"thin.\"",
        purpose: "Pragmatic meat preservation (salting/smoking) and psychological closure for those lost during the year."
      },
      "winter_solstice" => {
        month: 9, day: 25,
        name: "Winter Solstice (Yule)",
        gregorian: "Dec 21",
        action: "Bringing evergreen plants (holly, ivy, pine) indoors and burning a massive oak log (the Yule Log) for 12 days.",
        symbolism: "The log's light represented the returning sun; evergreens symbolized life that does not die in winter.",
        purpose: "Maintaining morale during the coldest, darkest period and providing a heat source for communal gathering."
      },
      "imbolc" => {
        month: 11, day: 11,
        name: "Imbolc",
        gregorian: "Feb 1",
        action: "Cleaning out the hearth and making \"Brigid's Crosses\" from rushes or straw.",
        symbolism: "Watching for the first signs of the thaw (like a badger or a groundhog emerging).",
        purpose: "Preparation for the new agricultural cycle. If the weather was clear, it was an omen that winter would last longer; if it was stormy, winter was ending."
      },
      "year_day" => {
        month: nil, day: nil,
        name: "Year Day",
        gregorian: "March 19",
        action: "Wearing masks to hide identity; the \"Lord of Misrule\" (a commoner) was given temporary power over the local leader.",
        symbolism: "A \"reset\" of the social clock where all debts and hierarchies were momentarily ignored.",
        purpose: "A pressure-release valve for social tensions before the new year began."
      }
    }.freeze

    def initialize(target_date = Date.current)
      @target_date = target_date
    end

    def to_equinox_calendar
      year = @target_date.year
      # Define start as March 20 of the current (or previous) year
      start_date = Date.new(year, 3, 20)

      # If today is before March 20, we are still in the previous year's cycle
      start_date = Date.new(year - 1, 3, 20) if @target_date < start_date

      days_since_start = (@target_date - start_date).to_i + 1
      is_leap = Date.leap?(start_date.year)

      # Leap Day comes after Junius 28 (day 168 = 6 months * 28 days)
      # So day 169 in a leap year is Leap Day
      if is_leap && days_since_start == 169
        return {
          type: :leap_day,
          display: "Leap Day",
          month_index: nil,
          day: nil,
          year_cycle_start: start_date,
          cycle_year: start_date.year
        }
      end

      # Year Day is the last day: day 365 in non-leap, day 366 in leap
      year_day_number = is_leap ? 366 : 365
      if days_since_start == year_day_number
        return {
          type: :year_day,
          display: "Year Day",
          month_index: nil,
          day: nil,
          year_cycle_start: start_date,
          cycle_year: start_date.year
        }
      end

      # Adjust for leap day: if we're past day 169 in a leap year, subtract 1
      adjusted_day = (is_leap && days_since_start > 169) ? days_since_start - 1 : days_since_start

      month_idx = (adjusted_day - 1) / DAYS_PER_MONTH
      day_of_month = (adjusted_day - 1) % DAYS_PER_MONTH + 1

      {
        type: :regular,
        display: "#{MONTHS[month_idx]} #{day_of_month}",
        month_name: MONTHS[month_idx],
        month_index: month_idx,
        day: day_of_month,
        year_cycle_start: start_date,
        cycle_year: start_date.year
      }
    end

    def self.month_name(index)
      MONTHS[index]
    end

    def self.days_per_month
      DAYS_PER_MONTH
    end

    def self.ritual_for_day(month_index, day)
      RITUAL_DAYS.each_value do |ritual|
        return ritual if ritual[:month] == month_index && ritual[:day] == day
      end
      nil
    end

    def self.ritual_for_year_day
      RITUAL_DAYS["year_day"]
    end

    def self.has_ritual?(target_date)
      converter = new(target_date)
      calendar_data = converter.to_equinox_calendar

      case calendar_data[:type]
      when :year_day
        true
      when :leap_day
        false
      when :regular
        ritual_for_day(calendar_data[:month_index], calendar_data[:day]).present?
      else
        false
      end
    end

    def has_ritual?
      self.class.has_ritual?(@target_date)
    end

    def to_formatted_string
      calendar_data = to_equinox_calendar

      case calendar_data[:type]
      when :year_day
        "Year Day, #{calendar_data[:cycle_year]}"
      when :leap_day
        "Leap Day, #{calendar_data[:cycle_year]}"
      when :regular
        day_of_week_index = (calendar_data[:day] - 1) % 7
        day_name = DAY_NAMES[day_of_week_index]
        "#{day_name}, #{calendar_data[:month_name]} #{calendar_data[:day]}, #{calendar_data[:cycle_year]}"
      end
    end
  end
end
