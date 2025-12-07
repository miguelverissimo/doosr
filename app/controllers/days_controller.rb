class DaysController < ApplicationController
  before_action :authenticate_user!
  layout -> { Views::Layouts::AppLayout.new(pathname: request.path, selected_date: @date) }

  def show
    @date = parse_date
    @day = current_user.days.includes(:descendant).find_or_create_by!(date: @date)
    @is_today = @date == Date.today

    render Views::Days::Show.new(
      day: @day,
      date: @date,
      is_today: @is_today
    )
  end

  def create
    @date = parse_date
    @day = current_user.days.find_or_initialize_by(date: @date)

    if @day.new_record? && @day.save
      redirect_to day_path(date: @date), notice: "Day opened successfully"
    else
      redirect_to day_path(date: @date), alert: "Day already exists"
    end
  end

  private

  def parse_date
    if params[:date].present?
      Date.parse(params[:date])
    else
      Date.today
    end
  rescue ArgumentError
    Date.today
  end
end
