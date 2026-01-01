# frozen_string_literal: true

class ::Components::Icon < ::Components::Base
  def initialize(name:, size: "24", class: nil, stroke_width: "2", **attrs)
    @name = name.to_sym
    @size = size.to_s
    @icon_class = binding.local_variable_get(:class)
    @stroke_width = stroke_width.to_s
    super(**attrs)
  end

  def view_template
    svg(
      xmlns: "http://www.w3.org/2000/svg",
      width: @size,
      height: @size,
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      stroke_width: @stroke_width,
      stroke_linecap: "round",
      stroke_linejoin: "round",
      class: @icon_class,
      **@attrs
    ) do |s|
      render_icon_paths(s)
    end
  end

  private

  def render_icon_paths(svg_element)
    case @name
    when :edit
      svg_element.path(d: "M12 20h9")
      svg_element.path(d: "M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z")
    when :delete
      svg_element.path(d: "M3 6h18")
      svg_element.path(d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2")
    when :check
      svg_element.polyline(points: "20 6 9 17 4 12")
    when :check_circle
      svg_element.path(d: "M22 11.08V12a10 10 0 1 1-5.93-9.14")
      svg_element.polyline(points: "22 4 12 14.01 9 11.01")
    when :circle
      svg_element.circle(cx: "12", cy: "12", r: "10")
    when :clock
      svg_element.circle(cx: "12", cy: "12", r: "10")
      svg_element.polyline(points: "12 6 12 12 16 14")
    when :x
      svg_element.path(d: "M18 6 6 18")
      svg_element.path(d: "m6 6 12 12")
    when :rotate_ccw
      svg_element.path(d: "M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8")
      svg_element.path(d: "M3 3v5h5")
    when :git_branch
      svg_element.line(x1: "6", x2: "6", y1: "3", y2: "15")
      svg_element.circle(cx: "18", cy: "6", r: "3")
      svg_element.circle(cx: "6", cy: "18", r: "3")
      svg_element.path(d: "M18 9a9 9 0 0 1-9 9")
    when :arrow_up
      svg_element.path(d: "m5 12 7-7 7 7")
      svg_element.path(d: "M12 19V5")
    when :arrow_down
      svg_element.path(d: "M12 5v14")
      svg_element.path(d: "m19 12-7 7-7-7")
    when :bug
      svg_element.path(d: "m8 2 1.88 1.88")
      svg_element.path(d: "M14.12 3.88 16 2")
      svg_element.path(d: "M9 7.13v-1a3.003 3.003 0 1 1 6 0v1")
      svg_element.path(d: "M12 20c-3.3 0-6-2.7-6-6v-3a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v3c0 3.3-2.7 6-6 6")
      svg_element.path(d: "M12 20v-9")
      svg_element.path(d: "M6.53 9C4.6 8.8 3 7.1 3 5")
      svg_element.path(d: "M6 13H2")
      svg_element.path(d: "M3 21c0-2.1 1.7-3.9 3.8-4")
      svg_element.path(d: "M20.97 5c0 2.1-1.6 3.8-3.5 4")
      svg_element.path(d: "M22 13h-4")
      svg_element.path(d: "M17.2 17c2.1.1 3.8 1.9 3.8 4")
    when :move
      svg_element.polyline(points: "5 9 2 12 5 15")
      svg_element.polyline(points: "9 5 12 2 15 5")
      svg_element.polyline(points: "15 19 12 22 9 19")
      svg_element.polyline(points: "19 9 22 12 19 15")
      svg_element.line(x1: "2", x2: "22", y1: "12", y2: "12")
      svg_element.line(x1: "12", x2: "12", y1: "2", y2: "22")
    when :recycle
      svg_element.path(d: "M7 19H4.815a1.83 1.83 0 0 1-1.57-.881 1.785 1.785 0 0 1-.004-1.784L7.196 9.5")
      svg_element.path(d: "M11 19h8.203a1.83 1.83 0 0 0 1.556-.89 1.784 1.784 0 0 0 0-1.775l-1.226-2.12")
      svg_element.path(d: "m14 16-3 3 3 3")
      svg_element.path(d: "M8.293 13.596 7.196 9.5 3.1 10.598")
      svg_element.path(d: "m9.344 5.811 1.093-1.892A1.83 1.83 0 0 1 11.985 3a1.784 1.784 0 0 1 1.546.888l3.943 6.843")
      svg_element.path(d: "m13.378 9.633 4.096 1.098 1.097-4.096")
    when :more_vertical
      svg_element.circle(cx: "12", cy: "12", r: "1")
      svg_element.circle(cx: "12", cy: "5", r: "1")
      svg_element.circle(cx: "12", cy: "19", r: "1")
    when :hash
      svg_element.line(x1: "4", x2: "20", y1: "9", y2: "9")
      svg_element.line(x1: "4", x2: "20", y1: "15", y2: "15")
      svg_element.line(x1: "10", x2: "8", y1: "3", y2: "21")
      svg_element.line(x1: "16", x2: "14", y1: "3", y2: "21")
    when :calendar
      svg_element.path(d: "M8 2v4")
      svg_element.path(d: "M16 2v4")
      svg_element.rect(width: "18", height: "18", x: "3", y: "4", rx: "2")
      svg_element.path(d: "M3 10h18")
    when :droplet
      svg_element.path(d: "M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z")
    when :list
      svg_element.line(x1: "8", x2: "21", y1: "6", y2: "6")
      svg_element.line(x1: "8", x2: "21", y1: "12", y2: "12")
      svg_element.line(x1: "8", x2: "21", y1: "18", y2: "18")
      svg_element.line(x1: "3", x2: "3.01", y1: "6", y2: "6")
      svg_element.line(x1: "3", x2: "3.01", y1: "12", y2: "12")
      svg_element.line(x1: "3", x2: "3.01", y1: "18", y2: "18")
    when :settings
      svg_element.path(d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z")
      svg_element.circle(cx: "12", cy: "12", r: "3")
    when :user
      svg_element.path(d: "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2")
      svg_element.circle(cx: "12", cy: "7", r: "4")
    when :email, :at_sign
      svg_element.circle(cx: "12", cy: "12", r: "4")
      svg_element.path(d: "M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8")
    when :phone, :telephone
      svg_element.path(d: "M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384")
    when :log_out
      svg_element.path(d: "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4")
      svg_element.polyline(points: "16 17 21 12 16 7")
      svg_element.line(x1: "21", x2: "9", y1: "12", y2: "12")
    when :accounting
      svg_element.circle(cx: "12", cy: "12", r: "10")
      svg_element.path(d: "M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8")
      svg_element.path(d: "M12 18V6")
    when :convert_currency
      svg_element.path(d: "M12 18H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5")
      svg_element.path(d: "M18 12h.01")
      svg_element.path(d: "M19 22v-6")
      svg_element.path(d: "m22 19-3-3-3 3")
      svg_element.path(d: "M6 12h.01")
      svg_element.circle(cx: "12", cy: "12", r: "2")
    when :no_currency_conversion
      svg_element.path(d: "M13 18H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5")
      svg_element.path(d: "m17 17 5 5")
      svg_element.path(d: "M18 12h.01")
      svg_element.path(d: "m22 17-5 5")
      svg_element.path(d: "M6 12h.01")
      svg_element.circle(cx: "12", cy: "12", r: "2")
    when :checklist
      svg_element.path(d: "M13 5h8")
      svg_element.path(d: "M13 12h8")
      svg_element.path(d: "M13 19h8")
      svg_element.path(d: "m3 17 2 2 4-4")
      svg_element.rect(x: "3", y: "4", width: "6", height: "6", rx: "1")
    when :currency_euro
      svg_element.path(d: "M4 10h12")
      svg_element.path(d: "M4 14h9")
      svg_element.path(d: "M19 6a7.7 7.7 0 0 0-5.2-2A7.9 7.9 0 0 0 6 12c0 4.4 3.5 8 7.8 8 2 0 3.8-.8 5.2-2")
    when :currency_usd
      svg_element.line(x1: "12", x2: "12", y1: "2", y2: "22")
      svg_element.path(d: "M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6")
    when :currency_cad
      svg_element.line(x1: "12", x2: "12", y1: "2", y2: "22")
      svg_element.path(d: "M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6")
    when :new_invoice
      svg_element.path(d: "M15 18h-5")
      svg_element.path(d: "M18 14h-8")
      svg_element.path(d: "M4 22h16a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v16a2 2 0 0 1-4 0v-9a2 2 0 0 1 2-2h2")
      svg_element.rect(width: "8", height: "4", x: "10", y: "6", rx: "1")
    when :draft
      svg_element.rect(x: "2", y: "6", width: "20", height: "8", rx: "1")
      svg_element.path(d: "M17 14v7")
      svg_element.path(d: "M7 14v7")
      svg_element.path(d: "M17 3v3")
      svg_element.path(d: "M7 3v3")
      svg_element.path(d: "M10 14 2.3 6.3")
      svg_element.path(d: "m14 6 7.7 7.7")
      svg_element.path(d: "m8 6 8 8")
    when :send
      svg_element.path(d: "M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z")
      svg_element.path(d: "m21.854 2.147-10.94 10.939")
    when :paid
      svg_element.path(d: "M11 15h2a2 2 0 1 0 0-4h-3c-.6 0-1.1.2-1.4.6L3 17")
      svg_element.path(d: "m7 21 1.6-1.4c.3-.4.8-.6 1.4-.6h4c1.1 0 2.1-.4 2.8-1.2l4.6-4.4a2 2 0 0 0-2.75-2.91l-4.2 3.9")
      svg_element.path(d: "m2 16 6 6")
      svg_element.circle(cx: "16", cy: "9", r: "2.9")
      svg_element.circle(cx: "6", cy: "5", r: "3")
    when :eye
      svg_element.path(d: "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z")
      svg_element.circle(cx: "12", cy: "12", r: "3")
    when :bank
      svg_element.path(d: "M10 18v-7")
      svg_element.path(d: "M11.12 2.198a2 2 0 0 1 1.76.006l7.866 3.847c.476.233.31.949-.22.949H3.474c-.53 0-.695-.716-.22-.949z")
      svg_element.path(d: "M14 18v-7")
      svg_element.path(d: "M18 18v-7")
      svg_element.path(d: "M3 22h18")
      svg_element.path(d: "M6 18v-7")
    when :created_date
      svg_element.path(d: "M8 2v4")
      svg_element.path(d: "M16 2v4")
      svg_element.rect(width: "18", height: "18", x: "3", y: "4", rx: "2")
      svg_element.path(d: "M3 10h18")
      svg_element.path(d: "M10 16h4")
      svg_element.path(d: "M12 14v4")
    when :due_date
      svg_element.path(d: "M16 14v2.2l1.6 1")
      svg_element.path(d: "M16 2v4")
      svg_element.path(d: "M21 7.5V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h3.5")
      svg_element.path(d: "M3 10h5")
      svg_element.path(d: "M8 2v4")
      svg_element.circle(cx: "16", cy: "16", r: "6")
    when :payment_date
      svg_element.path(d: "M8 2v4")
      svg_element.path(d: "M16 2v4")
      svg_element.path(d: "M21 14V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h8")
      svg_element.path(d: "M3 10h18")
      svg_element.path(d: "m16 20 2 2 4-4")
    when :download
      svg_element.path(d: "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z")
      svg_element.path(d: "M14 2v5a1 1 0 0 0 1 1h5")
      svg_element.path(d: "M12 18v-6")
      svg_element.path(d: "m9 15 3 3 3-3")
    when :file
      svg_element.path(d: "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z")
      svg_element.path(d: "M14 2v5a1 1 0 0 0 1 1h5")
      svg_element.path(d: "M12 18v-6")
      svg_element.path(d: "m9 15 3 3 3-3")
    when :no_file
      svg_element.path(d: "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z")
      svg_element.path(d: "M14 2v5a1 1 0 0 0 1 1h5")
      svg_element.path(d: "m14.5 12.5-5 5")
      svg_element.path(d: "m9.5 12.5 5 5")
    when :chevron_left
      svg_element.path(d: "m15 18-6-6 6-6")
    when :chevron_right
      svg_element.path(d: "m9 18 6-6-6-6")
    when :chevrons_left
      svg_element.path(d: "m11 17-5-5 5-5")
      svg_element.path(d: "m18 17-5-5 5-5")
    when :chevrons_right
      svg_element.path(d: "m6 17 5-5-5-5")
      svg_element.path(d: "m13 17 5-5-5-5")
    when :chevron_down
      svg_element.path(d: "m6 9 6 6 6-6")
    when :chevron_up
      svg_element.path(d: "m18 15-6-6-6 6")
    when :link
      svg_element.path(d: "M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71")
      svg_element.path(d: "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71")
    else
      # Unknown icon - render nothing or a placeholder
      svg_element.path(d: "M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z")
      svg_element.path(d: "M9.1 9a3 3 0 0 1 5.82 1c0 2-3 3-3 3")
      svg_element.path(d: "M12 17h.01")
    end
  end
end
