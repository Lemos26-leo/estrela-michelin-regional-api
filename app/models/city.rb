# Alimenta o filtro de região do UC-C04. A busca não usa API de mapas:
# a cidade é escolhida em lista, por isso basta o nome e a unidade federativa.
class City < ApplicationRecord
  has_many :restaurants, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :state, case_sensitive: false }
  validates :state, presence: true

  scope :by_name, -> { order(:name, :state) }
end
