# RN-C09: guarda as buscas do cliente. O cliente logado é simulado pelo
# cabeçalho X-Client-Id; sem ele, nada é gravado.
class SearchHistory < ApplicationRecord
  LIMIT_PER_CLIENT = 50

  validates :client_id, presence: true

  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :most_recent_first, -> { order(created_at: :desc, id: :desc) }

  # Grava os critérios e mantém só as 50 buscas mais recentes do cliente.
  def self.record(client_id:, criteria:)
    return nil if client_id.blank?

    history = create!(client_id: client_id, criteria: criteria)
    prune(client_id)
    history
  end

  def self.prune(client_id)
    keep = for_client(client_id).most_recent_first.limit(LIMIT_PER_CLIENT).pluck(:id)
    for_client(client_id).where.not(id: keep).delete_all
  end
end
