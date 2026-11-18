require "test_helper"

# Um teste por regra da busca do UC-C04.
class RestaurantSearchTest < ActiveSupport::TestCase
  setup do
    @italiana = tag("Italiana", :cuisine)
    @japonesa = tag("Japonesa", :cuisine)
    @romantico = tag("Jantar romântico", :occasion)
    @familia = tag("Com a família", :occasion)
    @aconchegante = tag("Aconchegante", :vibe)
    @animado = tag("Animado", :vibe)
    @estacionamento = tag("Estacionamento", :amenity)
    @acessivel = tag("Acessível", :amenity)
  end

  # RN-C01
  test "critério em branco não vira filtro" do
    restaurant(name: "Cantina", tags: [ @italiana, @romantico, @aconchegante ])

    search = RestaurantSearch.new({ city_id: "", cuisines: [ "", nil ], min_rating: "", vibes: [] })

    assert_empty search.criteria.informed_keys
    assert_predicate search, :valid?
    assert_equal [ "Cantina" ], search_names(search.call)
  end

  # RN-E05
  test "pendente, reprovado, sem tag obrigatória ou sem preço ficam fora da lista" do
    restaurant(name: "Elegível", tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Pendente", status: :pending, approved_at: nil,
               tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Reprovado", status: :rejected, approved_at: nil,
               tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Sem vibe", tags: [ @italiana, @romantico ])
    restaurant(name: "Sem ocasião", tags: [ @italiana, @aconchegante ])
    restaurant(name: "Sem preço", price_range: nil,
               tags: [ @italiana, @romantico, @aconchegante ])

    assert_equal [ "Elegível" ], search_names(RestaurantSearch.new.call)
  end

  # RN-C02
  test "ordena por compatibilidade e deixa fora quem fica abaixo de 40%" do
    restaurant(name: "Combina tudo", price_range: 2,
               tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Combina em parte", price_range: 3,
               tags: [ @japonesa, @romantico, @aconchegante ])
    restaurant(name: "Combina pouco", price_range: 4,
               tags: [ @japonesa, @familia, @aconchegante ])

    result = RestaurantSearch.new({
      occasions: [ @romantico.id ], vibes: [ @aconchegante.id ],
      cuisines: [ @italiana.id ], price_ranges: [ 2 ]
    }).call

    assert_equal "compatibility", result.ordering
    assert_equal [ "Combina tudo", "Combina em parte" ], search_names(result)
    assert_equal [ 100, 68 ], result.items.map(&:compatibility)
  end

  # RN-C02: as tags que pontuaram, na ordem culinária, ocasião, vibe.
  test "mostra as tags coincidentes" do
    restaurant(name: "Cantina", tags: [ @italiana, @romantico, @familia, @aconchegante ])

    result = RestaurantSearch.new({
      cuisines: [ @italiana.id ], occasions: [ @romantico.id ], vibes: [ @aconchegante.id ]
    }).call

    assert_equal [ "Italiana", "Jantar romântico", "Aconchegante" ], result.items.first.matched_tags
  end

  # RN-C02, fluxo 1a
  test "sem ocasião nem vibe ordena por nota e não calcula compatibilidade" do
    restaurant(name: "Nota 4,2", average_rating: 4.2, tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Nota 4,8", average_rating: 4.8, tags: [ @japonesa, @familia, @animado ])
    restaurant(name: "Nota 4,5", average_rating: 4.5, tags: [ @italiana, @familia, @animado ])

    result = RestaurantSearch.new({ cuisines: [ @italiana.id ] }).call

    assert_equal "rating", result.ordering
    assert_equal [ "Nota 4,8", "Nota 4,5", "Nota 4,2" ], search_names(result)
    assert_equal [ nil, nil, nil ], result.items.map(&:compatibility)
  end

  test "sem contexto, nota igual desempata pelo nome" do
    restaurant(name: "Bistrô", average_rating: 4.4, tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Adega", average_rating: 4.4, tags: [ @italiana, @romantico, @aconchegante ])

    assert_equal [ "Adega", "Bistrô" ], search_names(RestaurantSearch.new.call)
  end

  # Decisão do grupo: culinária e preço entram só como peso.
  test "culinária e preço não eliminam restaurantes" do
    restaurant(name: "Outra culinária", price_range: 4,
               tags: [ @japonesa, @romantico, @aconchegante ])

    result = RestaurantSearch.new({
      occasions: [ @romantico.id ], vibes: [ @aconchegante.id ],
      cuisines: [ @italiana.id ], price_ranges: [ 1 ]
    }).call

    assert_equal [ "Outra culinária" ], search_names(result)
    assert_equal 60, result.items.first.compatibility
  end

  test "cidade, nota mínima e comodidades eliminam restaurantes" do
    restaurant(name: "Em Londrina", city_name: "Londrina",
               tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Nota baixa", average_rating: 3.2,
               tags: [ @italiana, @romantico, @aconchegante ])
    restaurant(name: "Sem estacionamento",
               tags: [ @italiana, @romantico, @aconchegante, @acessivel ])
    restaurant(name: "Atende tudo", average_rating: 4.5,
               tags: [ @italiana, @romantico, @aconchegante, @estacionamento, @acessivel ])

    result = RestaurantSearch.new({
      city_id: city("Maringá").id,
      min_rating: "4.0",
      amenities: [ @estacionamento.id, @acessivel.id ]
    }).call

    assert_equal [ "Atende tudo" ], search_names(result)
  end

  # RF23
  test "selo Novidade vale aos 29 dias e não vale aos 31" do
    novo = restaurant(name: "Novo", approved_at: 29.days.ago,
                      tags: [ @italiana, @romantico, @aconchegante ])
    antigo = restaurant(name: "Antigo", approved_at: 31.days.ago,
                        tags: [ @italiana, @romantico, @aconchegante ])

    search = RestaurantSearch.new

    assert search.new?(novo)
    assert_not search.new?(antigo)
  end

  # Fluxo 5c
  test "sem resultado, sugere o critério que devolve mais restaurantes" do
    4.times do |index|
      restaurant(name: "Cantina #{index}", average_rating: 4.0,
                 tags: [ @italiana, @romantico, @aconchegante ])
    end

    result = RestaurantSearch.new({
      occasions: [ @romantico.id ], vibes: [ @aconchegante.id ], min_rating: "4.9"
    }).call

    assert_empty result.items
    assert_equal "min_rating", result.suggestion.remove
    assert_equal 4, result.suggestion.would_return
  end

  test "sem resultado e sem critério que ajude, não sugere nada" do
    result = RestaurantSearch.new({ min_rating: "4.9" }).call

    assert_empty result.items
    assert_nil result.suggestion
  end

  test "com resultado não sugere remover critério" do
    restaurant(name: "Cantina", tags: [ @italiana, @romantico, @aconchegante ])

    assert_nil RestaurantSearch.new({ cuisines: [ @italiana.id ] }).call.suggestion
  end

  # RN-C09
  test "grava o histórico quando a busca traz o cliente" do
    assert_difference -> { SearchHistory.count }, 1 do
      RestaurantSearch.new({ cuisines: [ @italiana.id ] }, client_id: "cliente-1").call
    end

    assert_equal [ @italiana.id ], SearchHistory.last.criteria["cuisines"]
  end

  test "não grava histórico sem o cliente" do
    assert_no_difference -> { SearchHistory.count } do
      RestaurantSearch.new({ cuisines: [ @italiana.id ] }).call
    end
  end

  test "cidade inexistente é parâmetro inválido" do
    search = RestaurantSearch.new({ city_id: 999_999 })

    assert_not_predicate search, :valid?
    assert_equal [ "city_id" ], search.invalid_fields
  end

  test "tag de outra categoria é parâmetro inválido" do
    assert_equal [ "occasions" ], RestaurantSearch.new({ occasions: [ @italiana.id ] }).invalid_fields
  end

  test "faixa de preço fora de 1 a 4 é parâmetro inválido" do
    assert_equal [ "price_ranges" ], RestaurantSearch.new({ price_ranges: [ 2, 9 ] }).invalid_fields
  end

  test "valor que não é número é parâmetro inválido" do
    search = RestaurantSearch.new({ city_id: "abc", min_rating: "muito bom" })

    assert_equal [ "city_id", "min_rating" ], search.invalid_fields
  end

  test "busca com critério inválido não é executada" do
    assert_raises(ArgumentError) { RestaurantSearch.new({ city_id: 999_999 }).call }
  end
end
