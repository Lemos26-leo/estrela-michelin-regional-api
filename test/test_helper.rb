ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Os dados de cada teste são montados no próprio teste, não em fixtures:
# a busca depende de combinações de tags que ficam mais claras escritas
# junto da regra que estão provando.
module SearchData
  # Cidade reaproveitada dentro do mesmo teste.
  def city(name = "Maringá", state: "PR")
    @cities ||= {}
    @cities[[ name, state ]] ||= City.create!(name: name, state: state)
  end

  def tag(name, category)
    Tag.find_or_create_by!(name: name, category: category)
  end

  # Restaurante elegível por padrão (RN-E05): aprovado, com faixa de preço
  # e com as tags de vibe e ocasião que o chamador passar.
  def restaurant(name:, tags: [], city_name: "Maringá", neighborhood: "Centro",
                 price_range: 2, status: :approved, approved_at: 60.days.ago,
                 average_rating: 4.0)
    record = Restaurant.create!(
      name: name,
      city: city(city_name),
      neighborhood: neighborhood,
      address: "Rua #{name}, 1",
      price_range: price_range,
      status: status,
      approved_at: approved_at,
      average_rating: average_rating
    )
    record.tags = tags
    record
  end

  def search_names(result)
    result.items.map { |item| item.restaurant.name }
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include SearchData
  end
end
