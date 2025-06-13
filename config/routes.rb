Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "login" => "sessions#new", as: :login
  delete "logout" => "sessions#destroy", as: :logout

  # Letter Opener Web for development email preview
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Magic Link Authentication (integrated with sessions)
  post "magic_link" => "sessions#magic_link", as: :magic_link
  get "magic_link/:token" => "sessions#verify_magic_link", as: :verify_magic_link

  get "signup" => "registrations#new", as: :signup
  post "signup" => "registrations#create"

  resources :passwords, param: :token, only: %i[new create edit update]

  resources :projects do
    resources :invitations, only: [ :index, :create, :destroy ]
    # Payment confirmation routes for project creators
    resources :payment_confirmations, only: [ :index, :show, :update ] do
      collection do
        patch :batch_update
      end
      member do
        post :add_note
      end
    end
    # Billing cycle management routes
    resources :billing_cycles do
      member do
        post :generate_upcoming
      end
    end
    member do
      get :preview_reminder
      get :reminder_settings
    end
  end

  # Payment routes
  resources :payments, only: [ :index, :show, :update, :destroy ] do
    member do
      get :download_evidence
    end
  end

  # Nested payment routes under billing cycles
  resources :billing_cycles, only: [] do
    resources :payments, only: [ :new, :create ]
  end

  # Invitation acceptance routes (public, no authentication required)
  get "invitations/:token" => "invitations#show", as: :invitation
  post "invitations/:token/accept" => "invitations#accept", as: :accept_invitation
  post "invitations/:token/confirm" => "invitations#confirm", as: :confirm_invitation
  post "invitations/:token/decline" => "invitations#decline", as: :decline_invitation

  # Unsubscribe routes (public, no authentication required)
  get "unsubscribe/:token" => "unsubscribe#show", as: :unsubscribe
  post "unsubscribe/:token" => "unsubscribe#create", as: :process_unsubscribe

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  get "create_flash" => "pages#create_flash"
  root "pages#home"
end
