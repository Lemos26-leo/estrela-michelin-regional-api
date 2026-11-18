class RestaurantSearch
  # Critérios da busca, já normalizados. Nada aqui toca o banco: o objeto
  # só sabe quais critérios foram informados e como se apresentar.
  #
  # RN-C01: parâmetro ausente ou em branco não vira filtro. Valor que não
  # dá para ler como número fica registrado em +malformed+, para a resposta
  # 422 do contrato.
  class Criteria
    KEYS = %i[city_id cuisines occasions vibes price_ranges min_rating amenities].freeze
    TAG_KEYS = %i[cuisines occasions vibes amenities].freeze

    # Categoria de tag de cada critério de tag.
    TAG_CATEGORIES = {
      cuisines: :cuisine,
      occasions: :occasion,
      vibes: :vibe,
      amenities: :amenity
    }.freeze

    attr_reader(*KEYS)
    attr_reader :malformed

    def self.from_params(params)
      malformed = []

      new(
        city_id: parse_integer(params[:city_id], :city_id, malformed),
        cuisines: parse_integer_list(params[:cuisines], :cuisines, malformed),
        occasions: parse_integer_list(params[:occasions], :occasions, malformed),
        vibes: parse_integer_list(params[:vibes], :vibes, malformed),
        price_ranges: parse_integer_list(params[:price_ranges], :price_ranges, malformed),
        min_rating: parse_decimal(params[:min_rating], :min_rating, malformed),
        amenities: parse_integer_list(params[:amenities], :amenities, malformed),
        malformed: malformed.uniq
      )
    end

    def initialize(city_id: nil, cuisines: [], occasions: [], vibes: [], price_ranges: [],
                   min_rating: nil, amenities: [], malformed: [])
      @city_id = city_id
      @cuisines = cuisines
      @occasions = occasions
      @vibes = vibes
      @price_ranges = price_ranges
      @min_rating = min_rating
      @amenities = amenities
      @malformed = malformed
    end

    def informed?(key)
      value = public_send(key)
      value.is_a?(Array) ? value.any? : value.present?
    end

    def informed_keys
      KEYS.select { |key| informed?(key) }
    end

    # Fluxo 1a: sem ocasião nem vibe não há contexto para pontuar.
    def context?
      informed?(:occasions) || informed?(:vibes)
    end

    # Mesma busca sem um dos critérios, para a sugestão do fluxo 5c.
    def without(key)
      attributes = to_h
      attributes[key] = public_send(key).is_a?(Array) ? [] : nil
      self.class.new(**attributes, malformed: malformed)
    end

    def to_h
      KEYS.index_with { |key| public_send(key) }
    end

    # Ids de tag pedidos na categoria, na ordem em que serão exibidos.
    def tag_ids(key)
      public_send(key)
    end

    def self.parse_integer(value, key, malformed)
      return nil if value.blank?

      parsed = Integer(value.to_s.strip, exception: false)
      malformed << key if parsed.nil?
      parsed
    end
    private_class_method :parse_integer

    def self.parse_integer_list(values, key, malformed)
      Array(values)
        .reject { |value| value.blank? }
        .filter_map { |value| parse_integer(value, key, malformed) }
        .uniq
    end
    private_class_method :parse_integer_list

    def self.parse_decimal(value, key, malformed)
      return nil if value.blank?

      parsed = Float(value.to_s.strip, exception: false)
      malformed << key if parsed.nil?
      parsed
    end
    private_class_method :parse_decimal
  end
end
