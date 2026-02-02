# frozen_string_literal: true

module Api
  module V1
    module Banking
      class CategoriesController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Categories"
          description "Manage transaction categories"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/categories", "List categories"
        description "Returns top-level categories with nested subcategories. Use flat=true for a flat list."
        param :flat, String, desc: "If 'true', returns flat list instead of nested", required: false
        def index
          if params[:flat] == "true"
            categories = current_user.categories.order(:name)
            render json: {
              data: categories.map { |c| serialize_category(c) },
              meta: { total_count: categories.count }
            }, status: :ok
          else
            categories = current_user.categories.top_level.with_subcategories.order(:name)
            render json: {
              data: categories.map { |c| serialize_category_with_subcategories(c) },
              meta: { total_count: categories.count }
            }, status: :ok
          end
        end

        api :GET, "/banking/categories/:id", "Show a category"
        param :id, :number, desc: "Category ID", required: true
        def show
          category = current_user.categories.includes(:subcategories).find(params[:id])

          render json: {
            data: serialize_category_with_subcategories(category),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/categories", "Create a category"
        param :category, Hash, desc: "Category attributes", required: true do
          param :name, String, desc: "Category name", required: true
          param :color, String, desc: "Color (hex)", required: false
          param :parent_id, :number, desc: "Parent category ID for subcategories", required: false
        end
        def create
          category = current_user.categories.build(category_params)

          if category.save
            render json: {
              data: serialize_category(category),
              meta: {}
            }, status: :created
          else
            render_error(
              category.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: category.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/categories/:id", "Update a category"
        param :id, :number, desc: "Category ID", required: true
        param :category, Hash, desc: "Category attributes", required: true do
          param :name, String, desc: "Category name", required: false
          param :color, String, desc: "Color (hex)", required: false
          param :parent_id, :number, desc: "Parent category ID", required: false
        end
        def update
          category = current_user.categories.find(params[:id])

          if category.update(category_params)
            render json: {
              data: serialize_category(category),
              meta: {}
            }, status: :ok
          else
            render_error(
              category.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: category.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/categories/:id", "Delete a category"
        description "Deletes a category. Subcategories will have their parent_id set to null."
        param :id, :number, desc: "Category ID", required: true
        def destroy
          category = current_user.categories.find(params[:id])
          category.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def category_params
          params.require(:category).permit(:name, :color, :parent_id)
        end

        def serialize_category(category)
          {
            id: category.id,
            name: category.name,
            color: category.color,
            parent_id: category.parent_id,
            created_at: category.created_at.iso8601,
            updated_at: category.updated_at.iso8601
          }
        end

        def serialize_category_with_subcategories(category)
          data = serialize_category(category)
          if category.subcategories.loaded? || category.respond_to?(:subcategories)
            data[:subcategories] = category.subcategories.map { |sc| serialize_category(sc) }
          end
          data
        end
      end
    end
  end
end
