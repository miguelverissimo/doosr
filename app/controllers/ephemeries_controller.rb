class EphemeriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @date = parse_date
    @ephemeries = Ephemery.affecting_date(@date)

    respond_to do |format|
      format.turbo_stream do
        component_html = render_to_string(
          ::Views::Ephemeries::List.new(
            ephemeries: @ephemeries,
            selected_date: @date
          )
        )
        Rails.logger.debug "Ephemeries component HTML length: #{component_html.length}"
        render turbo_stream: turbo_stream.append("body", component_html)
      end
      format.html do
        render ::Views::Ephemeries::List.new(
          ephemeries: @ephemeries,
          selected_date: @date
        )
      end
      format.json do
        render json: @ephemeries
      end
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
