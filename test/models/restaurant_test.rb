require "test_helper"

class RestaurantTest < ActiveSupport::TestCase
  setup do
    @cuisine = tag("Italiana", :cuisine)
    @occasion = tag("Jantar romântico", :occasion)
    @vibe = tag("Aconchegante", :vibe)
  end

  # RN-E05
  test "base elegível exige aprovação, faixa de preço, vibe e ocasião" do
    elegivel = restaurant(name: "Elegível", tags: [ @cuisine, @occasion, @vibe ])
    restaurant(name: "Pendente", status: :pending, approved_at: nil,
               tags: [ @cuisine, @occasion, @vibe ])
    restaurant(name: "Sem preço", price_range: nil, tags: [ @cuisine, @occasion, @vibe ])
    restaurant(name: "Sem vibe", tags: [ @cuisine, @occasion ])
    restaurant(name: "Sem ocasião", tags: [ @cuisine, @vibe ])

    assert_equal [ elegivel.id ], Restaurant.eligible.pluck(:id)
  end

  # RF23
  test "selo Novidade vale aos 29 dias e não vale aos 31" do
    assert_predicate restaurant(name: "Novo", approved_at: 29.days.ago), :recently_approved?
    assert_not_predicate restaurant(name: "Antigo", approved_at: 31.days.ago), :recently_approved?
  end

  test "restaurante sem data de aprovação não recebe o selo" do
    assert_not_predicate restaurant(name: "Sem data", approved_at: nil), :recently_approved?
  end

  test "faixa de preço aceita 1 a 4 ou nada" do
    assert_predicate Restaurant.new(name: "X", city: city, price_range: 5), :invalid?
    assert_predicate Restaurant.new(name: "X", city: city, price_range: nil), :valid?
  end

  test "nota fica entre 0 e 5" do
    assert_predicate Restaurant.new(name: "X", city: city, average_rating: 5.1), :invalid?
  end
end
