# frozen_string_literal: true

class JournalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal, only: [ :show, :destroy ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @search_query = params[:search_query]
    @page = params[:page] || 1

    journals_query = current_user.journals.ordered_by_date

    # Apply search if query present
    if @search_query.present?
      journals_query = journals_query.search_by_date(@search_query)
    end

    @journals = journals_query.page(@page).per(5)

    respond_to do |format|
      format.html do
        render ::Views::Journals::Index.new(
          journals: @journals,
          search_query: @search_query,
          page: @page
        )
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "journals_filter_section",
          ::Views::Journals::List.new(
            journals: @journals,
            search_query: @search_query,
            page: @page
          )
        )
      end
    end
  end

  def show
    # Open or create journal and auto-create scheduled prompts
    result = ::Journals::OpenOrCreateService.call(user: current_user, date: @journal.date)
    @journal = result[:journal]

    # Build tree to display journal with prompts and fragments
    @tree = ::ItemTree::Build.call(@journal.descendant, root_label: "journal")

    respond_to do |format|
      format.html do
        render ::Views::Journals::Show.new(
          journal: @journal,
          tree: @tree
        )
      end
    end
  end

  def new
    @journal = current_user.journals.build(date: Date.today)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Journals::FormDialog.new(journal: @journal))
        )
      end
    end
  end

  def create
    @journal = current_user.journals.build(journal_params)

    if @journal.save
      # Auto-create scheduled prompts
      ::Journals::OpenOrCreateService.call(user: current_user, date: @journal.date)
      @journal.reload

      respond_to do |format|
        format.html { redirect_to journal_path(@journal) }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("journal_dialog"),
            turbo_stream.append("body", "<script>window.toast && window.toast('Journal created successfully', { type: 'success' });</script>"),
            turbo_stream.action(:redirect, journal_path(@journal))
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "journal_form_errors",
            "<div class='text-sm text-destructive'>#{@journal.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    # Remove from all parent descendants before destroying
    @journal.parent_descendants.each do |descendant|
      descendant.remove_active_record("Journal", @journal.id)
      descendant.remove_inactive_record("Journal", @journal.id)
      descendant.save!
    end

    @journal.destroy!

    respond_to do |format|
      format.html { redirect_to journals_path, notice: "Journal deleted successfully" }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("body", "<script>window.toast && window.toast('Journal deleted successfully', { type: 'success' });</script>"),
          turbo_stream.action(:redirect, journals_path)
        ]
      end
    end
  end

  private

  def set_journal
    @journal = current_user.journals.find(params[:id])
  end

  def journal_params
    params.require(:journal).permit(:date)
  end
end
