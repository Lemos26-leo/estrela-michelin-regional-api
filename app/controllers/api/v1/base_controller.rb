module Api
  module V1
    class BaseController < ApplicationController
      # O cliente logado do RN-C09 é simulado pelo cabeçalho X-Client-Id.
      # Sem ele, a busca acontece e nada é gravado no histórico.
      def client_id
        request.headers["X-Client-Id"].presence
      end
    end
  end
end
