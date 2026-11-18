module Api
  module V1
    class RestaurantsController < BaseController
      # GET /api/v1/restaurants/search — UC-C04.
      def search
        search = RestaurantSearch.new(search_params, client_id: client_id)

        unless search.valid?
          return render json: { error: "invalid_params", fields: search.invalid_fields },
                        status: 422
        end

        result = search.call

        render json: {
          ordering: result.ordering,
          results: result.items.map { |item| result_json(item, search) },
          suggestion: suggestion_json(result.suggestion)
        }
      end

      private

      # Todos os parâmetros são opcionais (RN-C01).
      def search_params
        params
          .permit(:city_id, :min_rating,
                  cuisines: [], occasions: [], vibes: [], price_ranges: [], amenities: [])
          .to_h
          .symbolize_keys
      end

      def result_json(item, search)
        restaurant = item.restaurant

        {
          id: restaurant.id,
          name: restaurant.name,
          city: restaurant.city.name,
          neighborhood: restaurant.neighborhood,
          price_range: restaurant.price_range,
          average_rating: restaurant.average_rating.to_f,
          compatibility: item.compatibility,
          matched_tags: item.matched_tags,
          is_new: search.new?(restaurant)
        }
      end

      def suggestion_json(suggestion)
        return nil if suggestion.nil?

        { remove: suggestion.remove, would_return: suggestion.would_return }
      end
    end
  end
end
