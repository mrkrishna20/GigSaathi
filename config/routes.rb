Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
  get "assistant", to: "assistant#index", as: :assistant
  post "assistant/ask", to: "assistant#ask", as: :ask_assistant
  get "sign-up", to: "users#new", as: :new_user
  post "sign-up", to: "users#create", as: :users
  get "sign-in", to: "sessions#new", as: :new_session
  post "sign-in", to: "sessions#create", as: :session
  delete "sign-out", to: "sessions#destroy", as: :destroy_session
  resources :earnings, only: %i[index create destroy]
  get "complaint-help", to: "complaints#new", as: :new_complaint
  post "complaint-help/generate", to: "complaints#create", as: :generate_complaint
end
