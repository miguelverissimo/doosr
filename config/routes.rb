Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               sessions: "users/sessions",
               registrations: "users/registrations",
               omniauth_callbacks: "users/omniauth_callbacks"
             }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

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

  # Ephemeries - astrological aspects
  get 'ephemeries', to: 'ephemeries#index', as: :ephemeries

  # Items - core todo/task items
  resources :items, only: [:create, :update, :destroy] do
    member do
      get 'actions', to: 'items#actions_sheet', as: 'actions_sheet'
      get 'defer_options', to: 'items#defer_options', as: 'defer_options'
      patch 'toggle_state', to: 'items#toggle_state', as: 'toggle_state'
      patch 'move', to: 'items#move', as: 'move'
      patch 'reparent', to: 'items#reparent', as: 'reparent'
      patch 'defer', to: 'items#defer', as: 'defer'
      get 'debug', to: 'items#debug', as: 'debug'
    end
  end

  # Settings - user preferences and configuration
  resource :settings, only: [:show, :update] do
    post 'sections', to: 'settings#add_section', as: 'add_section'
    patch 'sections/edit', to: 'settings#edit_section', as: 'edit_section'
    delete 'sections/:section_name', to: 'settings#remove_section', as: 'remove_section'
    patch 'sections/:section_name/move', to: 'settings#move_section', as: 'move_section'
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
