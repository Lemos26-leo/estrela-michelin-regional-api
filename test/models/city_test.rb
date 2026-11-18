require "test_helper"

class CityTest < ActiveSupport::TestCase
  test "nome é único dentro do estado" do
    City.create!(name: "Maringá", state: "PR")

    assert_predicate City.new(name: "Maringá", state: "PR"), :invalid?
    assert_predicate City.new(name: "Maringá", state: "SP"), :valid?
  end

  test "nome e estado são obrigatórios" do
    assert_predicate City.new, :invalid?
  end
end
