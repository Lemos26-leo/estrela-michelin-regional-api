module Api
  module V1
    # Cidades e tags por categoria, para o front montar os filtros.
    class SearchOptionsController < BaseController
      # Opções de nota mínima oferecidas na interface.
      MIN_RATINGS = [ 3.0, 3.5, 4.0, 4.5 ].freeze

      def show
        render json: {
          cities: City.by_name.map { |city| { id: city.id, name: city.name, state: city.state } },
          tags: tags_by_category,
          price_ranges: Restaurant::PRICE_RANGES.to_a,
          min_ratings: MIN_RATINGS
        }
      end

      private

      def tags_by_category
        grouped = Tag.by_name.group_by(&:category)

        Tag.categories.keys.index_with do |category|
          Array(grouped[category]).map { |tag| { id: tag.id, name: tag.name } }
        end
      end
    end
  end
end
