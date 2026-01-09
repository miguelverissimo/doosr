# frozen_string_literal: true

class JournalPromptTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [ :edit, :update, :destroy ]
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) }

  def index
    @templates = current_user.journal_prompt_templates.order(created_at: :desc)

    respond_to do |format|
      format.html do
        render ::Views::JournalPromptTemplates::Index.new(templates: @templates)
      end
    end
  end

  def new
    @template = current_user.journal_prompt_templates.build

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::JournalPromptTemplates::FormDialog.new(template: @template))
        )
      end
    end
  end

  def create
    cleaned_params = template_params
    clean_schedule_rule!(cleaned_params)

    @template = current_user.journal_prompt_templates.build(cleaned_params)

    if @template.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("template_dialog"),
            turbo_stream.prepend(
              "templates_list",
              render_to_string(::Views::JournalPromptTemplates::TemplateRow.new(template: @template), layout: false)
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Prompt created successfully', { type: 'success' });</script>")
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "template_form_errors",
            "<div class='text-sm text-destructive'>#{@template.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::JournalPromptTemplates::FormDialog.new(template: @template))
        )
      end
    end
  end

  def update
    cleaned_params = template_params
    clean_schedule_rule!(cleaned_params)

    if @template.update(cleaned_params)
      @template.reload
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("template_dialog"),
            turbo_stream.replace(
              "template_#{@template.id}",
              render_to_string(::Views::JournalPromptTemplates::TemplateRow.new(template: @template), layout: false)
            ),
            turbo_stream.append("body", "<script>window.toast && window.toast('Prompt updated successfully', { type: 'success' });</script>")
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "template_form_errors",
            "<div class='text-sm text-destructive'>#{@template.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @template.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("template_#{@template.id}"),
          turbo_stream.append("body", "<script>window.toast && window.toast('Prompt deleted successfully', { type: 'success' });</script>")
        ]
      end
    end
  end

  private

  def set_template
    @template = current_user.journal_prompt_templates.find(params[:id])
  end

  def template_params
    params.require(:journal_prompt_template).permit(:prompt_text, :active, schedule_rule: [ :frequency, :day_of_month, :interval, days_of_week: [] ])
  end

  def clean_schedule_rule!(params)
    return unless params[:schedule_rule]

    rule = params[:schedule_rule]
    frequency = rule[:frequency]

    # If frequency is blank, set empty hash
    if frequency.blank?
      params[:schedule_rule] = {}
      return
    end

    # Build clean schedule_rule based on frequency
    cleaned_rule = { frequency: frequency }

    case frequency
    when "day_of_month"
      cleaned_rule[:day_of_month] = rule[:day_of_month].to_i if rule[:day_of_month].present?
    when "specific_weekdays"
      if rule[:days_of_week].present?
        cleaned_rule[:days_of_week] = rule[:days_of_week].compact.reject(&:blank?).map(&:to_i)
      end
    when "every_n_days"
      cleaned_rule[:interval] = rule[:interval].to_i if rule[:interval].present?
    end

    params[:schedule_rule] = cleaned_rule
  end
end
