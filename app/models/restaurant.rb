class Restaurant < ApplicationRecord
  # Janela do selo "Novidade" (RF23).
  NEW_WINDOW = 30.days

  # Faixas de preço válidas, em cifrões na interface.
  PRICE_RANGES = (1..4).freeze

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  belongs_to :city
  has_many :restaurant_tags, dependent: :destroy
  has_many :tags, through: :restaurant_tags

  validates :name, presence: true
  validates :price_range, inclusion: { in: PRICE_RANGES }, allow_nil: true
  validates :average_rating,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  scope :with_tag_in, ->(category) {
    where(id: RestaurantTag.joins(:tag).where(tags: { category: Tag.categories.fetch(category.to_s) }).select(:restaurant_id))
  }

  # RN-E05: só entram na busca os restaurantes aprovados, com faixa de preço
  # e com as tags obrigatórias de vibe e ocasião.
  scope :eligible, -> {
    approved.where.not(price_range: nil).with_tag_in(:vibe).with_tag_in(:occasion)
  }

  # RF23: selo "Novidade" para quem foi aprovado há menos de 30 dias.
  def recently_approved?(now = Time.current)
    approved? && approved_at.present? && approved_at > now - NEW_WINDOW
  end
end
