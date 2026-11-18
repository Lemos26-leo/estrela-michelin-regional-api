require "test_helper"

class Api::V1::SearchOptionsControllerTest < ActionDispatch::IntegrationTest
  test "devolve cidades, tags por categoria, faixas de preço e notas" do
    city("Maringá")
    city("Londrina")
    italiana = tag("Italiana", :cuisine)
    romantico = tag("Jantar romântico", :occasion)

    get "/api/v1/search_options"

    assert_response :success
    body = response.parsed_body

    assert_equal [ "Londrina", "Maringá" ], body["cities"].pluck("name")
    assert_equal [ { "id" => italiana.id, "name" => "Italiana" } ], body["tags"]["cuisine"]
    assert_equal [ { "id" => romantico.id, "name" => "Jantar romântico" } ], body["tags"]["occasion"]
    assert_equal %w[cuisine occasion vibe amenity], body["tags"].keys
    assert_equal [ 1, 2, 3, 4 ], body["price_ranges"]
    assert_equal [ 3.0, 3.5, 4.0, 4.5 ], body["min_ratings"]
  end

  test "sem dados devolve listas vazias" do
    get "/api/v1/search_options"

    assert_response :success
    assert_empty response.parsed_body["cities"]
    assert_empty response.parsed_body["tags"]["vibe"]
  end
end
