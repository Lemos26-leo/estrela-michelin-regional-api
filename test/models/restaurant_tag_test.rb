require "test_helper"

class RestaurantTagTest < ActiveSupport::TestCase
  test "o par restaurante e tag é único" do
    cuisine = tag("Italiana", :cuisine)
    cantina = restaurant(name: "Cantina", tags: [ cuisine ])

    assert_predicate RestaurantTag.new(restaurant: cantina, tag: cuisine), :invalid?
  end
end
