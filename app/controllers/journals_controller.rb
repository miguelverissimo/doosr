# frozen_string_literal: true

class JournalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal, only: [ :show, :destroy ]
  before_action :set_journal_if_present, only: [ :lock ]
  before_action :check_journal_unlock, only: [ :show ]
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

  def lock
    return unless current_user.journal_protection_enabled?

    # Get session token and clear it
    session_token = cookies.encrypted[:journal_session_token] || request.headers["X-Journal-Session"]
    if session_token.present?
      cache_key = journal_session_cache_key(session_token)
      Rails.cache.delete(cache_key)
    end

    cookies.delete(:journal_session_token)

    respond_to do |format|
      format.turbo_stream do
        if @journal.present?
          # Locking from individual journal show page
          render turbo_stream: [
            turbo_stream.replace(
              "journal_content",
              render_to_string(::Views::Journals::Locked.new(journal: @journal), layout: false)
            ),
            turbo_stream.append("body", "<script>Turbo.cache.clear(); window.toast && window.toast('Journal locked', { type: 'success' });</script>")
          ]
        else
          # Locking from journals index page - clear cache and reload
          render turbo_stream: [
            turbo_stream.append("body", "<script>Turbo.cache.clear(); window.toast && window.toast('Journals locked', { type: 'success' }); setTimeout(() => Turbo.visit(window.location.href, { action: 'replace' }), 100);</script>")
          ]
        end
      end
    end
  end

  private

  def set_journal
    @journal = current_user.journals.find(params[:id])
  end

  def set_journal_if_present
    @journal = current_user.journals.find(params[:id]) if params[:id].present?
  end

  def check_journal_unlock
    return unless current_user.journal_protection_enabled?

    # Check cookie first, fall back to header for backwards compatibility
    session_token = cookies.encrypted[:journal_session_token] || request.headers["X-Journal-Session"]

    if session_token.blank? || !valid_journal_session?(session_token)
      respond_to do |format|
        format.html do
          render ::Views::Journals::Locked.new(journal: @journal)
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Journals::UnlockDialog.new)
          )
        end
      end
      return
    end

    session_data = Rails.cache.read(journal_session_cache_key(session_token))
    @encryption_key = Base64.strict_decode64(session_data[:encryption_key])
    Current.encryption_key = @encryption_key
  end

  def valid_journal_session?(token)
    cache_key = journal_session_cache_key(token)
    session_data = Rails.cache.read(cache_key)
    return false unless session_data
    return false unless session_data[:user_id] == current_user.id

    # Handle sessions created before timestamp tracking was added
    if session_data[:last_activity_at].nil?
      # Invalidate old sessions - require re-authentication
      Rails.cache.delete(cache_key)
      cookies.delete(:journal_session_token)
      return false
    end

    # Check if session has timed out due to inactivity
    timeout_minutes = current_user.journal_session_timeout_minutes
    last_activity = Time.at(session_data[:last_activity_at])
    if Time.current - last_activity > timeout_minutes.minutes
      # Session timed out - clean up
      Rails.cache.delete(cache_key)
      cookies.delete(:journal_session_token)
      return false
    end

    # Update last activity timestamp
    session_data[:last_activity_at] = Time.current.to_i
    Rails.cache.write(cache_key, session_data, expires_in: 24.hours)

    true
  end

  def journal_session_cache_key(token)
    "journal_session:#{current_user.id}:#{token}"
  end

  def journal_params
    params.require(:journal).permit(:date)
  end
end
