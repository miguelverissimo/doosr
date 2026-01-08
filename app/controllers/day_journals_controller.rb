# frozen_string_literal: true

class DayJournalsController < ApplicationController
  before_action :authenticate_user!
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def create
    @day = current_user.days.find(params[:day_id])

    # Create or find journal for the day's date
    result = ::Journals::OpenOrCreateService.call(user: current_user, date: @day.date_key)
    @journal = result[:journal]

    # Add to day's descendant if not already there
    unless @day.descendant.active_record?("Journal", @journal.id)
      @day.descendant.add_active_record("Journal", @journal.id)
      @day.descendant.save!
    end

    # Rebuild day tree
    tree = ::ItemTree::Build.call(@day.descendant, root_label: "day")

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "items_list",
            render_to_string(partial: "days/items_list", locals: { day: @day, tree: tree })
          ),
          turbo_stream.append("body", "<script>window.toast && window.toast('Journal added to day', { type: 'success' });</script>")
        ]
      end
    end
  end
end
