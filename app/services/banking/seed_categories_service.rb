# frozen_string_literal: true

module Banking
  class SeedCategoriesService
    DEFAULT_CATEGORIES = [
      { name: "Groceries", color: "#22c55e" },
      { name: "Fuel", color: "#f97316" },
      { name: "Subscriptions", color: "#8b5cf6" },
      { name: "Dining", color: "#ec4899" },
      { name: "Transport", color: "#3b82f6" },
      { name: "Shopping", color: "#eab308" },
      { name: "Bills", color: "#ef4444" },
      { name: "Entertainment", color: "#06b6d4" },
      { name: "Health", color: "#14b8a6" },
      { name: "Other", color: "#6b7280" }
    ].freeze

    def initialize(user)
      @user = user
    end

    def call
      DEFAULT_CATEGORIES.each do |category_data|
        @user.categories.find_or_create_by!(name: category_data[:name]) do |category|
          category.color = category_data[:color]
        end
      end
    end
  end
end
