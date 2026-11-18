# Estrela Michelin Regional — API

API Rails (modo `--api`) com PostgreSQL que atende o **UC-C04 Buscar
restaurantes por contexto**. O front que consome esta API está em
[`estrela-michelin-regional-web`](../estrela-michelin-regional-web); a
documentação do projeto fica em `estrela-michelin-regional`.

- Ruby 3.3 · Rails 8.1 · PostgreSQL 16
- Porta local: `3000`

## Rodar

Pré-requisitos: Ruby 3.3 ou mais novo, Docker (para o banco) e Git.

```bash
bundle install
docker compose up -d          # PostgreSQL 16 em localhost:5432
bin/rails db:prepare          # cria o banco e roda as migrations
bin/rails db:seed             # 3 cidades, 22 tags, 28 restaurantes
bin/rails server              # http://localhost:3000/up responde 200
```

O `docker-compose.yml` sobe o Postgres com usuário e senha `estrela`.
Quem já tiver um Postgres instalado pode pular o `docker compose` e
apontar para ele com as variáveis `DB_HOST`, `DB_USERNAME` e `DB_PASSWORD`.

O CORS libera `http://localhost:5173` (o front). Para outro endereço, use a
variável `FRONT_URL`.

### Sem Ruby instalado

Dá para rodar tudo por Docker, sem instalar Ruby na máquina. Crie a imagem
uma vez:

```bash
docker build -t emr-api-dev - <<'DOCKERFILE'
FROM ruby:3.3
RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev postgresql-client \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
DOCKERFILE
```

Depois, de dentro da pasta do projeto (`docker compose up -d` já rodando):

```bash
# comando genérico: troque o que vem depois do -lc
docker run --rm -it -v "$PWD:/app" -v emr-bundle:/usr/local/bundle -w /app \
  --network estrela-michelin-regional-api_default -e DB_HOST=db \
  emr-api-dev bash -lc "bundle install && bin/rails db:prepare && bin/rails db:seed"

# servidor na porta 3000
docker run --rm -it -v "$PWD:/app" -v emr-bundle:/usr/local/bundle -w /app \
  --network estrela-michelin-regional-api_default -e DB_HOST=db -p 3000:3000 \
  emr-api-dev bash -lc "bin/rails server -b 0.0.0.0"

# testes
docker run --rm -v "$PWD:/app" -v emr-bundle:/usr/local/bundle -w /app \
  --network estrela-michelin-regional-api_default -e DB_HOST=db \
  emr-api-dev bash -lc "bin/rails test"
```

O volume `emr-bundle` guarda as gems entre execuções, e `DB_HOST=db` aponta
para o Postgres do `docker-compose.yml`.

## Testes

```bash
bin/rails test
```

São 41 testes, um por regra da busca. Rodam contra o banco de teste, que o
`db:prepare` já cria.

## Endpoints

### `GET /api/v1/search_options`

Cidades e tags por categoria, para o front montar os filtros.

```json
{
  "cities": [{ "id": 1, "name": "Maringá", "state": "PR" }],
  "tags": {
    "cuisine": [{ "id": 1, "name": "Italiana" }],
    "occasion": [{ "id": 8, "name": "Jantar romântico" }],
    "vibe": [{ "id": 13, "name": "Aconchegante" }],
    "amenity": [{ "id": 18, "name": "Estacionamento" }]
  },
  "price_ranges": [1, 2, 3, 4],
  "min_ratings": [3.0, 3.5, 4.0, 4.5]
}
```

### `GET /api/v1/restaurants/search`

Executa a busca. Todos os parâmetros são opcionais: o que não vier não vira
filtro (RN-C01).

| Parâmetro | Tipo | Exemplo |
| --- | --- | --- |
| `city_id` | id de cidade | `1` |
| `cuisines[]` | ids de tag | `1` |
| `occasions[]` | ids de tag | `8` |
| `vibes[]` | ids de tag | `13`, `14` |
| `price_ranges[]` | 1 a 4 | `2`, `3` |
| `min_rating` | decimal | `4.0` |
| `amenities[]` | ids de tag | `18` |

```bash
curl "http://localhost:3000/api/v1/restaurants/search?city_id=1&occasions[]=8&vibes[]=13&price_ranges[]=2"
```

```json
{
  "ordering": "compatibility",
  "results": [
    {
      "id": 1,
      "name": "Cantina da Nonna",
      "city": "Maringá",
      "neighborhood": "Zona 7",
      "price_range": 2,
      "average_rating": 4.6,
      "compatibility": 100,
      "matched_tags": ["Italiana", "Jantar romântico", "Aconchegante"],
      "is_new": true
    }
  ],
  "suggestion": null
}
```

| Situação | Status | Corpo |
| --- | --- | --- |
| Sem ocasião nem vibe (fluxo 1a) | 200 | `"ordering": "rating"` e `compatibility` nulo |
| Nenhum resultado (fluxo 5c) | 200 | `results` vazio e `"suggestion": {"remove": "min_rating", "would_return": 4}` |
| Parâmetro inválido | 422 | `{"error": "invalid_params", "fields": ["city_id"]}` |

Com o cabeçalho `X-Client-Id`, a busca é gravada em `search_histories`
(RN-C09, simulando o cliente logado). Sem o cabeçalho, nada é gravado.

## Regras da busca

Tudo fica em `app/services/restaurant_search.rb`; o controller só repassa
parâmetros.

| Passo | Regra | Onde |
| --- | --- | --- |
| Descartar critérios vazios | RN-C01 | `RestaurantSearch::Criteria` |
| Base elegível: aprovado, com preço, vibe e ocasião | RN-E05 | `Restaurant.eligible` |
| Restrições: cidade, nota mínima e comodidades | | `RestaurantSearch#restricted` |
| Compatibilidade e corte de 40% | RN-C02 | `RestaurantSearch::Compatibility` |
| Ordenação: compatibilidade, ou nota sem contexto | RN-C02, fluxo 1a | `RestaurantSearch#sorted` |
| Selo "Novidade" (30 dias) | RF23 | `Restaurant#recently_approved?` |
| Sugerir o critério a remover | fluxo 5c | `RestaurantSearch#suggestion` |
| Histórico, 50 por cliente | RN-C09 | `SearchHistory.record` |
| Parâmetro inválido | | `RestaurantSearch::Validation` |

Pesos da compatibilidade, como o grupo decidiu: ocasião 30, vibe 30,
culinária 25 e faixa de preço 15, aplicados só aos critérios informados.
Culinária e preço não eliminam ninguém — entram apenas como peso. A faixa
de preço pontua 1 na faixa pedida, 0,5 na vizinha e 0 fora.

## Modelo de dados

| Tabela | Campos |
| --- | --- |
| `cities` | `name`, `state` (único por par) |
| `restaurants` | `name`, `city_id`, `neighborhood`, `address`, `price_range` (1 a 4), `status`, `approved_at`, `average_rating` |
| `tags` | `name`, `category` (`cuisine`, `occasion`, `vibe`, `amenity`), único por par |
| `restaurant_tags` | `restaurant_id`, `tag_id`, único por par |
| `search_histories` | `client_id`, `criteria` (jsonb), `created_at` |

O diagrama de classes está em [`docs/diagrama-de-classes.md`](docs/diagrama-de-classes.md).

O seed inclui os casos de borda que provam as regras: um restaurante
pendente, um reprovado, um sem vibe, um sem ocasião, um sem faixa de preço
(todos fora da busca) e dois aprovados há menos de 30 dias, que recebem o
selo "Novidade".

## Fora do escopo

Sem API de mapas e sem geolocalização: a região é um filtro de cidade
escolhido em lista. Por isso o fluxo 1c (região não reconhecida) não ocorre
e a ordenação do fluxo 1a usa apenas a nota, não a proximidade. O cadastro e
a aprovação de restaurantes (UC-E03, UC-E04, UC-A01) e o perfil do
restaurante (UC-C06) também ficam fora.
