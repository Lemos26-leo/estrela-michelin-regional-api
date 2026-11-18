# Libera o front (React + Vite) para chamar a API em outra porta.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONT_URL", "http://localhost:5173")
    resource "*", headers: :any, methods: %i[get post delete options]
  end
end
