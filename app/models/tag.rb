# Culinária, ocasião, vibe e comodidade ficam na mesma tabela, com categoria.
# Isso deixa o cálculo de compatibilidade (RN-C02) igual para todas.
class Tag < ApplicationRecord
  enum :category, { cuisine: 0, occasion: 1, vibe: 2, amenity: 3 }

  has_many :restaurant_tags, dependent: :destroy
  has_many :restaurants, through: :restaurant_tags

  validates :name, presence: true, uniqueness: { scope: :category, case_sensitive: false }
  validates :category, presence: true

  scope :by_name, -> { order(:name) }
end
