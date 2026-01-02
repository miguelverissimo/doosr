# frozen_string_literal: true

class FixedCalendarController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @target_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @converter = FixedCalendar::Converter.new(@target_date)
    @calendar_data = @converter.to_equinox_calendar
    @open_ritual = params[:open_ritual].present?

    render ::Views::FixedCalendar::Index.new(
      target_date: @target_date,
      calendar_data: @calendar_data,
      open_ritual: @open_ritual
    )
  end

  def ritual
    if params[:year_day].present?
      @ritual = FixedCalendar::Converter.ritual_for_year_day
    else
      month = params[:month].to_i
      day = params[:day].to_i
      @ritual = FixedCalendar::Converter.ritual_for_day(month, day)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "ritual_modal_container",
          ::Views::FixedCalendar::RitualModal.new(ritual: @ritual)
        )
      end
    end
  end
end
