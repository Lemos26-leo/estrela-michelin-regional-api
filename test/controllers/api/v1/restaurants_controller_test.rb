require "test_helper"

class Api::V1::RestaurantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @italiana = tag("Italiana", :cuisine)
    @romantico = tag("Jantar romântico", :occasion)
    @aconchegante = tag("Aconchegante", :vibe)
    @cantina = restaurant(name: "Cantina da Nonna", neighborhood: "Zona 7", price_range: 2,
                          average_rating: 4.6, approved_at: 12.days.ago,
                          tags: [ @italiana, @romantico, @aconchegante ])
  end

  test "responde no formato do contrato" do
    get "/api/v1/restaurants/search", params: {
      city_id: @cantina.city_id,
      cuisines: [ @italiana.id ],
      occasions: [ @romantico.id ],
      vibes: [ @aconchegante.id ],
      price_ranges: [ 2 ],
      min_rating: "4.0"
    }

    assert_response :success
    body = response.parsed_body

    assert_equal "compatibility", body["ordering"]
    assert_nil body["suggestion"]
    assert_equal(
      {
        "id" => @cantina.id,
        "name" => "Cantina da Nonna",
        "city" => "Maringá",
        "neighborhood" => "Zona 7",
        "price_range" => 2,
        "average_rating" => 4.6,
        "compatibility" => 100,
        "matched_tags" => [ "Italiana", "Jantar romântico", "Aconchegante" ],
        "is_new" => true
      },
      body["results"].sole
    )
  end

  test "sem critérios devolve a base elegível ordenada por nota" do
    restaurant(name: "Sushi Hanako", average_rating: 4.7,
               tags: [ @italiana, @romantico, @aconchegante ])

    get "/api/v1/restaurants/search"

    assert_response :success
    assert_equal "rating", response.parsed_body["ordering"]
    assert_equal [ "Sushi Hanako", "Cantina da Nonna" ],
                 response.parsed_body["results"].pluck("name")
  end

  test "sem resultado devolve a sugestão do fluxo 5c" do
    get "/api/v1/restaurants/search", params: {
      occasions: [ @romantico.id ], vibes: [ @aconchegante.id ], min_rating: "4.9"
    }

    assert_response :success
    assert_empty response.parsed_body["results"]
    assert_equal({ "remove" => "min_rating", "would_return" => 1 },
                 response.parsed_body["suggestion"])
  end

  test "parâmetro inválido devolve 422" do
    get "/api/v1/restaurants/search", params: { city_id: 999_999, price_ranges: [ 9 ] }

    assert_response 422
    assert_equal({ "error" => "invalid_params", "fields" => [ "city_id", "price_ranges" ] },
                 response.parsed_body)
  end

  # RN-C09
  test "com o cabeçalho X-Client-Id grava o histórico" do
    assert_difference -> { SearchHistory.count }, 1 do
      get "/api/v1/restaurants/search",
          params: { cuisines: [ @italiana.id ] },
          headers: { "X-Client-Id" => "cliente-1" }
    end

    assert_response :success
    assert_equal "cliente-1", SearchHistory.last.client_id
    assert_equal [ @italiana.id ], SearchHistory.last.criteria["cuisines"]
  end

  test "sem o cabeçalho não grava o histórico" do
    assert_no_difference -> { SearchHistory.count } do
      get "/api/v1/restaurants/search", params: { cuisines: [ @italiana.id ] }
    end

    assert_response :success
  end

  test "parâmetro inválido não grava o histórico" do
    assert_no_difference -> { SearchHistory.count } do
      get "/api/v1/restaurants/search",
          params: { city_id: 999_999 },
          headers: { "X-Client-Id" => "cliente-1" }
    end

    assert_response 422
  end
end
