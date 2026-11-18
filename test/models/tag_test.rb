require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "o mesmo nome pode existir em categorias diferentes" do
    Tag.create!(name: "Romântico", category: :occasion)

    assert_predicate Tag.new(name: "Romântico", category: :vibe), :valid?
    assert_predicate Tag.new(name: "Romântico", category: :occasion), :invalid?
  end

  test "as categorias são as quatro do modelo de dados" do
    assert_equal %w[cuisine occasion vibe amenity], Tag.categories.keys
  end
end
