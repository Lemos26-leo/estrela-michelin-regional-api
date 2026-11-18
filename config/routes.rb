Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Cidades e tags para montar os filtros.
      get "search_options", to: "search_options#show"

      # UC-C04 Buscar restaurantes por contexto.
      get "restaurants/search", to: "restaurants#search"
    end
  end

  # Responde 200 se a aplicação subiu sem erro.
  get "up" => "rails/health#show", as: :rails_health_check
end
