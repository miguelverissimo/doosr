Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Action Cable for real-time WebSocket connections
  mount ActionCable.server, at: '/cable'

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker", to: "rails/pwa#service_worker", as: :pwa_service_worker

  # Days - core feature
  get 'day', to: 'days#show', as: :day
  post 'days', to: 'days#create'
  resources :days, only: [] do
    member do
      patch 'close', to: 'days#close'
      patch 'reopen', to: 'days#reopen'
    end
    collection do
      post 'import', to: 'days#import'
    end
  end

  # Day migrations - import with custom settings
  resources :day_migrations, only: [:new, :create]

  # Ephemeries
  get 'ephemeries', to: 'ephemeries#index', as: :ephemeries

  # Lists - reusable item collections
  resources :lists do
    member do
      get 'actions', to: 'lists#actions_sheet', as: 'actions_sheet'
    end
  end

  # Public lists - accessible via slug without authentication
  get 'p/lists/:slug', to: 'public_lists#show', as: :public_list

  # Reusable items - items created in lists with duplicate detection
  # ALL list item actions go through this controller
  resources :reusable_items, only: [:create, :update, :destroy] do
    member do
      get 'actions', to: 'reusable_items#actions_sheet', as: 'actions_sheet'
      get 'edit_form', to: 'reusable_items#edit_form', as: 'edit_form'
      patch 'toggle_state', to: 'reusable_items#toggle_state', as: 'toggle_state'
      patch 'move', to: 'reusable_items#move', as: 'move'
      patch 'reparent', to: 'reusable_items#reparent', as: 'reparent'
      get 'debug', to: 'reusable_items#debug', as: 'debug'
    end
  end

  # Items - core todo/task items
  resources :items, only: [:create, :update, :destroy] do
    member do
      get 'actions', to: 'items#actions_sheet', as: 'actions_sheet'
      get 'edit_form', to: 'items#edit_form', as: 'edit_form'
      get 'defer_options', to: 'items#defer_options', as: 'defer_options'
      get 'recurrence_options', to: 'items#recurrence_options', as: 'recurrence_options'
      patch 'toggle_state', to: 'items#toggle_state', as: 'toggle_state'
      patch 'move', to: 'items#move', as: 'move'
      patch 'reparent', to: 'items#reparent', as: 'reparent'
      patch 'defer', to: 'items#defer', as: 'defer'
      patch 'undefer', to: 'items#undefer', as: 'undefer'
      patch 'update_recurrence', to: 'items#update_recurrence', as: 'update_recurrence'
      get 'debug', to: 'items#debug', as: 'debug'
    end
  end

  # Settings - user preferences and configuration
  resource :settings, only: [:show, :update] do
    post 'sections', to: 'settings#add_section', as: 'add_section'
    patch 'sections/edit', to: 'settings#edit_section', as: 'edit_section'
    delete 'sections/:section_name', to: 'settings#remove_section', as: 'remove_section'
    patch 'sections/:section_name/move', to: 'settings#move_section', as: 'move_section'
    patch 'migration_settings', to: 'settings#update_migration_settings', as: 'update_migration_settings'
    post 'migration_settings', to: 'settings#update_migration_settings' # Temporary fallback
  end

  # Accounting
  resources :accounting, only: [:index] do
    collection do
      resources :tax_brackets, 
        path: "settings/tax_brackets",
        controller: "accounting/settings/tax_brackets",
        as: "settings_tax_brackets"
      resources :addresses, 
        path: "settings/addresses",
        controller: "accounting/settings/addresses",
        as: "settings_addresses" do
          member do
            patch :activate
          end
        end
    end
  end

  # Authenticated users see the day view, unauthenticated users see sign in
  devise_scope :user do
    authenticated :user do
      root to: 'days#show', as: :authenticated_root
    end

    unauthenticated do
      root to: 'users/sessions#new', as: :unauthenticated_root
    end
  end
end
