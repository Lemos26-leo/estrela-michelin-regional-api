class RestaurantSearch
  # RN-C02: compatibilidade entre um restaurante e os critérios informados.
  #
  # compatibilidade = 100 × Σ(peso × pontuação) ÷ Σ(pesos), considerando só
  # os critérios que a pessoa informou. Os pesos são a proposta do grupo.
  class Compatibility
    WEIGHTS = { occasions: 30, vibes: 30, cuisines: 25, price_ranges: 15 }.freeze

    # Abaixo disso o restaurante não entra na lista.
    MINIMUM = 40

    # Ordem das tags coincidentes no cartão: culinária, ocasião, vibe.
    MATCHED_TAG_ORDER = %i[cuisines occasions vibes].freeze

    def initialize(criteria)
      @criteria = criteria
    end

    # Percentual inteiro, ou nil quando a busca não tem ocasião nem vibe
    # (fluxo 1a): sem contexto não há o que pontuar.
    def score(restaurant)
      return nil unless criteria.context?

      weights = WEIGHTS.select { |key, _| criteria.informed?(key) }
      return nil if weights.empty?

      weighted = weights.sum { |key, weight| weight * fraction(restaurant, key) }
      (100 * weighted / weights.values.sum).round
    end

    # As tags que pontuaram. Preço não é tag; comodidade é restrição, não peso.
    def matched_tags(restaurant)
      MATCHED_TAG_ORDER.flat_map do |key|
        next [] unless criteria.informed?(key)

        wanted = criteria.public_send(key)
        restaurant.tags.select { |tag| wanted.include?(tag.id) }.map(&:name).sort
      end
    end

    private

    attr_reader :criteria

    def fraction(restaurant, key)
      key == :price_ranges ? price_fraction(restaurant) : tag_fraction(restaurant, key)
    end

    # Fração das tags pedidas na categoria que o restaurante tem.
    def tag_fraction(restaurant, key)
      wanted = criteria.public_send(key)
      return 0r if wanted.empty?

      owned = restaurant.tags.count { |tag| wanted.include?(tag.id) }
      Rational(owned, wanted.size)
    end

    # 1 se está numa faixa pedida, 0,5 se é vizinha, 0 caso contrário.
    def price_fraction(restaurant)
      wanted = criteria.price_ranges
      return 0r if wanted.empty? || restaurant.price_range.nil?
      return 1r if wanted.include?(restaurant.price_range)
      return 1r / 2 if wanted.any? { |range| (range - restaurant.price_range).abs == 1 }

      0r
    end
  end
end
