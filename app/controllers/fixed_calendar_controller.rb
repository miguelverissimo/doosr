# frozen_string_literal: true

class FixedCalendarController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @target_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @converter = FixedCalendar::Converter.new(@target_date)
    @calendar_data = @converter.to_equinox_calendar

    render ::Views::FixedCalendar::Index.new(
      target_date: @target_date,
      calendar_data: @calendar_data
    )
  end
end
