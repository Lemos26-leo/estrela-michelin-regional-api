class RestaurantSearch
  # Confere os critérios contra o banco. Qualquer campo aqui vira a resposta
  # 422 do contrato: { "error": "invalid_params", "fields": ["city_id"] }.
  class Validation
    RATINGS = (0..5).freeze

    def initialize(criteria)
      @criteria = criteria
    end

    def invalid_fields
      fields = criteria.malformed.dup
      fields << :city_id if unknown_city?
      fields.concat(unknown_tag_keys)
      fields << :price_ranges if price_out_of_range?
      fields << :min_rating if rating_out_of_range?

      fields.uniq.sort_by { |field| Criteria::KEYS.index(field) || Criteria::KEYS.size }.map(&:to_s)
    end

    private

    attr_reader :criteria

    def unknown_city?
      criteria.informed?(:city_id) && !City.exists?(id: criteria.city_id)
    end

    # Tag inexistente ou de outra categoria.
    def unknown_tag_keys
      Criteria::TAG_CATEGORIES.filter_map do |key, category|
        next unless criteria.informed?(key)

        wanted = criteria.public_send(key)
        key unless Tag.where(id: wanted, category: category).count == wanted.size
      end
    end

    def price_out_of_range?
      criteria.informed?(:price_ranges) &&
        criteria.price_ranges.any? { |range| !Restaurant::PRICE_RANGES.include?(range) }
    end

    def rating_out_of_range?
      criteria.informed?(:min_rating) && !RATINGS.cover?(criteria.min_rating)
    end
  end
end
