# frozen_string_literal: true

module Banking
  class CategoriesController < BaseController
    before_action :set_category, only: [ :edit, :update, :destroy ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @categories = current_user.categories.top_level.with_subcategories.order(:name)

      respond_to do |format|
        format.html { redirect_to banking_path }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::Categories::IndexDialog.new(categories: @categories), layout: false)
          )
        end
      end
    end

    def list
      @categories = current_user.categories.top_level.with_subcategories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "categories_content",
            render_to_string(::Views::Banking::Categories::List.new(categories: @categories), layout: false)
          )
        end
      end
    end

    def new
      @category = current_user.categories.build
      @parent_categories = current_user.categories.top_level.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "categories_content",
            render_to_string(::Views::Banking::Categories::Form.new(
              category: @category,
              parent_categories: @parent_categories
            ), layout: false)
          )
        end
      end
    end

    def create
      @category = current_user.categories.build(category_params)

      if @category.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.remove("categories_dialog")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "category_form_errors",
              "<div class='text-sm text-destructive'>#{@category.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      @parent_categories = current_user.categories.top_level.where.not(id: @category.id).order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "categories_content",
            render_to_string(::Views::Banking::Categories::Form.new(
              category: @category,
              parent_categories: @parent_categories
            ), layout: false)
          )
        end
      end
    end

    def update
      if @category.update(category_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.remove("categories_dialog")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "category_form_errors",
              "<div class='text-sm text-destructive'>#{@category.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      @category.destroy!
      @categories = current_user.categories.top_level.with_subcategories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "categories_content",
            render_to_string(::Views::Banking::Categories::List.new(categories: @categories), layout: false)
          )
        end
      end
    end

    private

    def set_category
      @category = current_user.categories.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :color, :parent_id)
    end
  end
end
