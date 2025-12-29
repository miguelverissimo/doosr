# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: {
      theme: current_user.theme,
      permanent_sections: current_user.permanent_sections
    }
  end

  def update
    if current_user.update(settings_params)
      head :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_section
    section_name = params[:section_name]&.strip

    if section_name.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Section name cannot be empty', { type: 'error' });</script>")
        end
        format.json { render json: { error: "Section name cannot be empty" }, status: :unprocessable_entity }
      end
      return
    end

    sections = current_user.permanent_sections
    if sections.include?(section_name)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Section \"#{section_name}\" already exists', { type: 'error' });</script>")
        end
        format.json { render json: { error: "Section already exists" }, status: :unprocessable_entity }
      end
      return
    end

    sections << section_name
    current_user.permanent_sections = sections

    if current_user.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              "permanent_sections_list",
              ::Components::Settings::SectionsList.new(sections: current_user.permanent_sections)
            ),
            turbo_stream.append("body", "<script>document.querySelector('#add_section_form input[name=section_name]').value = '';</script>")
          ]
        end
        format.json { render json: { sections: current_user.permanent_sections } }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to save section', { type: 'error' });</script>")
        end
        format.json { render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def remove_section
    section_name = params[:section_name]
    sections = current_user.permanent_sections
    sections.delete(section_name)
    current_user.permanent_sections = sections

    if current_user.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "permanent_sections_list",
            ::Components::Settings::SectionsList.new(sections: current_user.permanent_sections)
          )
        end
        format.json { render json: { sections: current_user.permanent_sections } }
      end
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def edit_section
    old_name = params[:old_name]
    new_name = params[:new_name]&.strip

    if new_name.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Section name cannot be empty', { type: 'error' });</script>")
        end
        format.json { render json: { error: "Section name cannot be empty" }, status: :unprocessable_entity }
      end
      return
    end

    sections = current_user.permanent_sections
    old_index = sections.index(old_name)

    if old_index.nil?
      respond_to do |format|
        format.turbo_stream { head :not_found }
        format.json { render json: { error: "Section not found" }, status: :not_found }
      end
      return
    end

    if sections.include?(new_name) && new_name != old_name
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Section \"#{new_name}\" already exists', { type: 'error' });</script>")
        end
        format.json { render json: { error: "Section already exists" }, status: :unprocessable_entity }
      end
      return
    end

    sections[old_index] = new_name
    current_user.permanent_sections = sections

    if current_user.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "permanent_sections_list",
            ::Components::Settings::SectionsList.new(sections: current_user.permanent_sections)
          )
        end
        format.json { render json: { sections: current_user.permanent_sections } }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to save section', { type: 'error' });</script>")
        end
        format.json { render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def move_section
    section_name = params[:section_name]
    direction = params[:direction]
    sections = current_user.permanent_sections
    current_index = sections.index(section_name)

    if current_index
      new_index = direction == "up" ? current_index - 1 : current_index + 1

      if new_index >= 0 && new_index < sections.length
        sections[current_index], sections[new_index] = sections[new_index], sections[current_index]
        current_user.permanent_sections = sections

        if current_user.save
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "permanent_sections_list",
                ::Components::Settings::SectionsList.new(sections: current_user.permanent_sections)
              )
            end
            format.json { render json: { sections: current_user.permanent_sections } }
          end
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      else
        head :ok
      end
    else
      head :ok
    end
  end

  def update_migration_settings
    Rails.logger.info "=== UPDATE MIGRATION SETTINGS CALLED ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "day_migration_settings params: #{params[:day_migration_settings].inspect}"

    settings = parse_migration_settings(params[:day_migration_settings] || {})
    Rails.logger.info "Parsed settings: #{settings.inspect}"

    current_user.day_migration_settings = settings
    Rails.logger.info "User settings before save: #{current_user.settings.inspect}"
    Rails.logger.info "User changed?: #{current_user.changed?}"
    Rails.logger.info "Changed attributes: #{current_user.changes.inspect}"

    if current_user.save
      Rails.logger.info "User saved successfully!"
      Rails.logger.info "User day_migration_settings after save: #{current_user.reload.day_migration_settings.inspect}"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Migration settings saved successfully', { type: 'success' });</script>")
        end
        format.json { render json: { day_migration_settings: current_user.day_migration_settings } }
      end
    else
      Rails.logger.error "User save failed: #{current_user.errors.full_messages}"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to save migration settings', { type: 'error' });</script>")
        end
        format.json { render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def settings_params
    params.require(:user).permit(settings: [ :theme, permanent_sections: [] ])
  end

  def parse_migration_settings(settings_params)
    # Dynamically rebuild settings based on MigrationOptions structure
    # This ensures the entire object is replaced with form data (not merged)
    # Hidden fields send "false" for unchecked, checkboxes send "true" for checked
    result = {}

    # Process top-level options
    MigrationOptions.top_level_options.each do |key, _config|
      result[key.to_s] = settings_params[key] == "true"
    end

    # Process nested option groups
    MigrationOptions.nested_option_groups.each do |group_key, _group_config|
      result[group_key.to_s] = {}

      MigrationOptions.options_for_group(group_key).each do |option_key, _option_config|
        result[group_key.to_s][option_key.to_s] = settings_params.dig(group_key, option_key) == "true"
      end
    end

    result
  end
end
