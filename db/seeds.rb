# Dados da busca do UC-C04. O cadastro e a aprovação de restaurantes
# (UC-E03, UC-E04, UC-A01) não fazem parte desta entrega, então os
# restaurantes entram por aqui — inclusive os casos de borda que provam o
# filtro da base elegível (RN-E05) e o selo "Novidade" (RF23).
#
# Rode quantas vezes quiser: o seed é idempotente.

CITIES = [
  { name: "Maringá",  state: "PR" },
  { name: "Londrina", state: "PR" },
  { name: "Curitiba", state: "PR" }
].freeze

TAGS = {
  cuisine: [ "Italiana", "Japonesa", "Brasileira", "Árabe", "Vegetariana", "Peruana", "Francesa" ],
  occasion: [ "Jantar romântico", "Com a família", "Almoço de negócios", "Comemoração", "Encontro com amigos" ],
  vibe: [ "Aconchegante", "Animado", "Tranquilo", "Elegante", "Descontraído" ],
  amenity: [ "Estacionamento", "Acessível", "Aceita reserva", "Área externa", "Wi-Fi" ]
}.freeze

# approved_days_ago nulo significa sem data de aprovação.
RESTAURANTS = [
  { name: "Cantina da Nonna", city: "Maringá", neighborhood: "Zona 7", address: "Av. Brasil, 1200",
    price_range: 2, status: :approved, approved_days_ago: 12, average_rating: 4.6,
    tags: [ "Italiana", "Jantar romântico", "Comemoração", "Aconchegante", "Aceita reserva", "Estacionamento" ] },

  { name: "Casa Tulipa", city: "Maringá", neighborhood: "Centro", address: "Rua Néo Alves Martins, 340",
    price_range: 3, status: :approved, approved_days_ago: 400, average_rating: 4.4,
    tags: [ "Francesa", "Jantar romântico", "Elegante", "Aconchegante", "Aceita reserva" ] },

  { name: "Mesa do Porto", city: "Maringá", neighborhood: "Zona 5", address: "Av. Tuiuti, 88",
    price_range: 3, status: :approved, approved_days_ago: 200, average_rating: 4.2,
    tags: [ "Brasileira", "Comemoração", "Com a família", "Animado", "Estacionamento", "Área externa" ] },

  { name: "Sushi Hanako", city: "Maringá", neighborhood: "Zona 1", address: "Av. Paraná, 510",
    price_range: 3, status: :approved, approved_days_ago: 150, average_rating: 4.7,
    tags: [ "Japonesa", "Jantar romântico", "Almoço de negócios", "Tranquilo", "Elegante", "Aceita reserva", "Acessível" ] },

  { name: "Quintal do Zé", city: "Maringá", neighborhood: "Zona 4", address: "Rua Joubert de Carvalho, 77",
    price_range: 1, status: :approved, approved_days_ago: 300, average_rating: 3.9,
    tags: [ "Brasileira", "Encontro com amigos", "Descontraído", "Animado", "Área externa" ] },

  { name: "Verde Rama", city: "Maringá", neighborhood: "Zona 7", address: "Av. Mandacaru, 2100",
    price_range: 2, status: :approved, approved_days_ago: 25, average_rating: 4.5,
    tags: [ "Vegetariana", "Com a família", "Encontro com amigos", "Tranquilo", "Acessível", "Wi-Fi" ] },

  { name: "Beirute Maringá", city: "Maringá", neighborhood: "Centro", address: "Rua Santos Dumont, 455",
    price_range: 2, status: :approved, approved_days_ago: 500, average_rating: 4.1,
    tags: [ "Árabe", "Com a família", "Descontraído", "Estacionamento" ] },

  { name: "Forneria 44", city: "Maringá", neighborhood: "Zona 8", address: "Av. Colombo, 9000",
    price_range: 2, status: :approved, approved_days_ago: 90, average_rating: 4.3,
    tags: [ "Italiana", "Encontro com amigos", "Com a família", "Animado", "Área externa", "Estacionamento" ] },

  # Caso de borda: ainda pendente de aprovação, fica fora da busca (RN-E05).
  { name: "Alto da Serra", city: "Maringá", neighborhood: "Zona 2", address: "Rua Pioneiro Jacó, 15",
    price_range: 3, status: :pending, approved_days_ago: nil, average_rating: 4.8,
    tags: [ "Francesa", "Comemoração", "Elegante" ] },

  # Caso de borda: aprovado, mas sem tag de vibe (RN-E05).
  { name: "Bistrô do Largo", city: "Maringá", neighborhood: "Centro", address: "Praça Raposo Tavares, 20",
    price_range: 2, status: :approved, approved_days_ago: 120, average_rating: 4.4,
    tags: [ "Italiana", "Jantar romântico" ] },

  # Caso de borda: aprovado, mas sem tag de ocasião (RN-E05).
  { name: "Cozinha da Vila", city: "Maringá", neighborhood: "Zona 3", address: "Rua Pará, 600",
    price_range: 2, status: :approved, approved_days_ago: 120, average_rating: 4.2,
    tags: [ "Brasileira", "Aconchegante" ] },

  # Caso de borda: aprovado, mas sem faixa de preço (RN-E05).
  { name: "Cantina Provisória", city: "Maringá", neighborhood: "Zona 6", address: "Av. Morangueira, 1500",
    price_range: nil, status: :approved, approved_days_ago: 80, average_rating: 4.0,
    tags: [ "Italiana", "Com a família", "Aconchegante" ] },

  # Caso de borda: reprovado, fica fora da busca (RN-E05).
  { name: "Sabor Antigo", city: "Maringá", neighborhood: "Zona 9", address: "Rua Bahia, 310",
    price_range: 2, status: :rejected, approved_days_ago: nil, average_rating: 2.8,
    tags: [ "Brasileira", "Com a família", "Descontraído" ] },

  { name: "Trattoria Bella", city: "Londrina", neighborhood: "Gleba Palhano", address: "Av. Madre Leônia, 1400",
    price_range: 3, status: :approved, approved_days_ago: 220, average_rating: 4.5,
    tags: [ "Italiana", "Jantar romântico", "Comemoração", "Elegante", "Aceita reserva" ] },

  { name: "Boteco do Lago", city: "Londrina", neighborhood: "Centro", address: "Rua Sergipe, 1200",
    price_range: 1, status: :approved, approved_days_ago: 310, average_rating: 3.8,
    tags: [ "Brasileira", "Encontro com amigos", "Animado", "Descontraído", "Área externa" ] },

  { name: "Yamato", city: "Londrina", neighborhood: "Centro", address: "Av. Higienópolis, 300",
    price_range: 3, status: :approved, approved_days_ago: 180, average_rating: 4.4,
    tags: [ "Japonesa", "Almoço de negócios", "Tranquilo", "Estacionamento", "Acessível" ] },

  { name: "Horta e Grão", city: "Londrina", neighborhood: "Gleba Fazenda", address: "Rua Paranaguá, 55",
    price_range: 2, status: :approved, approved_days_ago: 60, average_rating: 4.6,
    tags: [ "Vegetariana", "Com a família", "Tranquilo", "Aconchegante", "Acessível", "Wi-Fi" ] },

  { name: "Esquina Árabe", city: "Londrina", neighborhood: "Vila Nova", address: "Rua Quintino Bocaiúva, 90",
    price_range: 2, status: :approved, approved_days_ago: 420, average_rating: 4.0,
    tags: [ "Árabe", "Com a família", "Encontro com amigos", "Descontraído" ] },

  { name: "Casa Peruana", city: "Londrina", neighborhood: "Gleba Palhano", address: "Av. Ayrton Senna, 700",
    price_range: 4, status: :approved, approved_days_ago: 95, average_rating: 4.7,
    tags: [ "Peruana", "Comemoração", "Jantar romântico", "Elegante", "Aceita reserva", "Estacionamento" ] },

  { name: "Padoca da Vila", city: "Londrina", neighborhood: "Vila Nova", address: "Rua Pernambuco, 410",
    price_range: 1, status: :approved, approved_days_ago: 600, average_rating: 3.7,
    tags: [ "Brasileira", "Com a família", "Descontraído", "Wi-Fi" ] },

  { name: "Madeira e Brasa", city: "Curitiba", neighborhood: "Batel", address: "Av. do Batel, 1200",
    price_range: 4, status: :approved, approved_days_ago: 260, average_rating: 4.8,
    tags: [ "Brasileira", "Comemoração", "Almoço de negócios", "Elegante", "Estacionamento", "Aceita reserva" ] },

  { name: "Osteria Fiore", city: "Curitiba", neighborhood: "Batel", address: "Rua Bispo Dom José, 2100",
    price_range: 3, status: :approved, approved_days_ago: 140, average_rating: 4.5,
    tags: [ "Italiana", "Jantar romântico", "Aconchegante", "Elegante", "Aceita reserva" ] },

  { name: "Tempurá Jardim", city: "Curitiba", neighborhood: "Água Verde", address: "Av. República Argentina, 900",
    price_range: 2, status: :approved, approved_days_ago: 330, average_rating: 4.2,
    tags: [ "Japonesa", "Com a família", "Tranquilo", "Acessível" ] },

  { name: "Bar do Mercado", city: "Curitiba", neighborhood: "Centro", address: "Av. Sete de Setembro, 1865",
    price_range: 1, status: :approved, approved_days_ago: 480, average_rating: 4.0,
    tags: [ "Brasileira", "Encontro com amigos", "Animado", "Área externa", "Wi-Fi" ] },

  { name: "Raízes Veganas", city: "Curitiba", neighborhood: "Alto da XV", address: "Rua XV de Novembro, 3100",
    price_range: 2, status: :approved, approved_days_ago: 45, average_rating: 4.4,
    tags: [ "Vegetariana", "Encontro com amigos", "Com a família", "Descontraído", "Aconchegante", "Acessível" ] },

  { name: "Le Petit Coin", city: "Curitiba", neighborhood: "Batel", address: "Rua Mateus Leme, 400",
    price_range: 4, status: :approved, approved_days_ago: 200, average_rating: 4.6,
    tags: [ "Francesa", "Jantar romântico", "Comemoração", "Elegante", "Tranquilo", "Aceita reserva" ] },

  { name: "Cantinho do Sul", city: "Curitiba", neighborhood: "Portão", address: "Av. República Argentina, 2500",
    price_range: 2, status: :approved, approved_days_ago: 370, average_rating: 3.9,
    tags: [ "Brasileira", "Com a família", "Descontraído", "Animado", "Estacionamento" ] },

  # Aprovado há 29 dias: ainda dentro da janela do selo "Novidade" (RF23).
  { name: "Nikkei Curitiba", city: "Curitiba", neighborhood: "Água Verde", address: "Rua Brigadeiro Franco, 1500",
    price_range: 3, status: :approved, approved_days_ago: 29, average_rating: 4.5,
    tags: [ "Japonesa", "Peruana", "Jantar romântico", "Comemoração", "Elegante", "Aceita reserva" ] }
].freeze

ActiveRecord::Base.transaction do
  cities = CITIES.to_h do |attributes|
    [ attributes[:name], City.find_or_create_by!(**attributes) ]
  end

  tags = TAGS.flat_map { |category, names|
    names.map { |name| Tag.find_or_create_by!(name: name, category: category) }
  }.index_by(&:name)

  RESTAURANTS.each do |attributes|
    days_ago = attributes[:approved_days_ago]

    restaurant = Restaurant.find_or_initialize_by(
      name: attributes[:name],
      city: cities.fetch(attributes[:city])
    )

    restaurant.update!(
      neighborhood: attributes[:neighborhood],
      address: attributes[:address],
      price_range: attributes[:price_range],
      status: attributes[:status],
      approved_at: days_ago && days_ago.days.ago,
      average_rating: attributes[:average_rating]
    )

    restaurant.tags = attributes.fetch(:tags).map { |name| tags.fetch(name) }
  end
end

puts "#{City.count} cidades, #{Tag.count} tags, #{Restaurant.count} restaurantes " \
     "(#{Restaurant.eligible.count} elegíveis para a busca)."
