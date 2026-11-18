require "test_helper"

class SearchHistoryTest < ActiveSupport::TestCase
  # RN-C09
  test "mantém as 50 buscas mais recentes de cada cliente" do
    60.times do |index|
      SearchHistory.record(client_id: "cliente-1", criteria: { city_id: index })
    end

    assert_equal SearchHistory::LIMIT_PER_CLIENT, SearchHistory.for_client("cliente-1").count

    guardadas = SearchHistory.for_client("cliente-1").pluck(Arel.sql("criteria->>'city_id'")).map(&:to_i)

    assert_equal (10..59).to_a, guardadas.sort
  end

  test "o histórico de um cliente não apaga o de outro" do
    SearchHistory.record(client_id: "cliente-1", criteria: {})
    SearchHistory.record(client_id: "cliente-2", criteria: {})

    assert_equal 1, SearchHistory.for_client("cliente-1").count
    assert_equal 1, SearchHistory.for_client("cliente-2").count
  end

  test "sem cliente não grava nada" do
    assert_no_difference -> { SearchHistory.count } do
      assert_nil SearchHistory.record(client_id: nil, criteria: { city_id: 1 })
      assert_nil SearchHistory.record(client_id: "", criteria: { city_id: 1 })
    end
  end
end
