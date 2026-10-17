Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
  get "assistant", to: "assistant#index", as: :assistant
  post "assistant/ask", to: "assistant#ask", as: :ask_assistant
  resources :earnings, only: %i[index create destroy]
  get "complaint-help", to: "complaints#new", as: :new_complaint
  post "complaint-help/generate", to: "complaints#create", as: :generate_complaint
end
