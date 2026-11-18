# UC-C04 Buscar restaurantes por contexto.
#
# Toda a regra da busca está aqui; o controller só repassa parâmetros. As
# etapas seguem a ordem do diagrama de sequência:
#
#   1. descartar critérios vazios (RN-C01), em Criteria
#   2. base elegível (RN-E05), em Restaurant.eligible
#   3. restrições: cidade, nota mínima e comodidades
#   4. compatibilidade (RN-C02), em Compatibility
#   5. ordenação: por compatibilidade, ou por nota sem contexto (fluxo 1a)
#   6. selo "Novidade" (RF23), em Restaurant#recently_approved?
#   7. sem resultado: sugerir o critério a remover (fluxo 5c)
#   8. histórico da busca (RN-C09), em SearchHistory
class RestaurantSearch
  Item = Struct.new(:restaurant, :compatibility, :matched_tags, keyword_init: true)
  Suggestion = Struct.new(:remove, :would_return, keyword_init: true)
  Result = Struct.new(:ordering, :items, :suggestion, keyword_init: true)

  # Desempate da sugestão do fluxo 5c, do critério mais restritivo para o
  # menos, quando dois deles devolveriam o mesmo número de restaurantes.
  SUGGESTION_ORDER = %i[min_rating amenities city_id price_ranges cuisines vibes occasions].freeze

  attr_reader :criteria

  # +params+ aceita os parâmetros da requisição ou um Criteria já montado.
  # +client_id+ vem do cabeçalho X-Client-Id e simula o cliente logado.
  def initialize(params = {}, client_id: nil, now: Time.current)
    @criteria = params.is_a?(Criteria) ? params : Criteria.from_params(params)
    @client_id = client_id
    @now = now
  end

  # Campos que a resposta 422 precisa listar.
  def invalid_fields
    @invalid_fields ||= Validation.new(criteria).invalid_fields
  end

  def valid?
    invalid_fields.empty?
  end

  def call
    raise ArgumentError, "critérios inválidos: #{invalid_fields.join(', ')}" unless valid?

    SearchHistory.record(client_id: @client_id, criteria: criteria.to_h) if @client_id.present?

    items = items_for(criteria)

    Result.new(
      ordering: criteria.context? ? "compatibility" : "rating",
      items: items,
      suggestion: items.empty? ? suggestion : nil
    )
  end

  # RF23, exposto para o serializer usar o mesmo instante da busca.
  def new?(restaurant)
    restaurant.recently_approved?(@now)
  end

  private

  def items_for(criteria)
    compatibility = Compatibility.new(criteria)

    items = restricted(criteria).map do |restaurant|
      Item.new(
        restaurant: restaurant,
        compatibility: compatibility.score(restaurant),
        matched_tags: compatibility.matched_tags(restaurant)
      )
    end

    sorted(items.reject { |item| below_minimum?(item) }, criteria)
  end

  # Base elegível mais as restrições. Culinária e preço não eliminam
  # ninguém: entram só como peso na compatibilidade.
  def restricted(criteria)
    scope = Restaurant.eligible.includes(:city, :tags)
    scope = scope.where(city_id: criteria.city_id) if criteria.informed?(:city_id)
    scope = scope.where(average_rating: criteria.min_rating..) if criteria.informed?(:min_rating)

    # Todas as comodidades pedidas são obrigatórias.
    criteria.amenities.each do |tag_id|
      scope = scope.where(id: RestaurantTag.where(tag_id: tag_id).select(:restaurant_id))
    end

    scope.to_a
  end

  def below_minimum?(item)
    item.compatibility.present? && item.compatibility < Compatibility::MINIMUM
  end

  def sorted(items, criteria)
    if criteria.context?
      items.sort_by { |item| [ -item.compatibility, -item.restaurant.average_rating, item.restaurant.name ] }
    else
      items.sort_by { |item| [ -item.restaurant.average_rating, item.restaurant.name ] }
    end
  end

  # Fluxo 5c: repetir a busca sem um critério por vez e sugerir o que
  # devolve mais restaurantes.
  def suggestion
    candidates = criteria.informed_keys.filter_map do |key|
      count = items_for(criteria.without(key)).size
      Suggestion.new(remove: key.to_s, would_return: count) if count.positive?
    end

    candidates.min_by do |candidate|
      [ -candidate.would_return, SUGGESTION_ORDER.index(candidate.remove.to_sym) || SUGGESTION_ORDER.size ]
    end
  end
end
