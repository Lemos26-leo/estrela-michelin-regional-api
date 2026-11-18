# Diagrama de classes — UC-C04 Buscar restaurantes por contexto

Alinhado ao modelo de dados (`db/schema.rb`) e ao serviço de busca
(`app/services/restaurant_search.rb`). Copie este arquivo para o repositório
de documentação, em `04-diagramas-de-classe/`.

## Entidades e serviço

```mermaid
classDiagram
    class City {
        +String name
        +String state
    }

    class Restaurant {
        +String name
        +String neighborhood
        +String address
        +Integer price_range
        +Status status
        +DateTime approved_at
        +Decimal average_rating
        +recently_approved(now) Boolean
        +eligible() Restaurant[]
    }

    class Tag {
        +String name
        +Category category
    }

    class RestaurantTag {
    }

    class SearchHistory {
        +String client_id
        +JSON criteria
        +DateTime created_at
        +record(client_id, criteria) SearchHistory
        +prune(client_id)
    }

    class RestaurantSearch {
        +invalid_fields() String[]
        +valid() Boolean
        +call() Result
        +new(restaurant) Boolean
        -items_for(criteria) Item[]
        -restricted(criteria) Restaurant[]
        -sorted(items, criteria) Item[]
        -suggestion() Suggestion
    }

    class Criteria {
        +Integer city_id
        +Integer[] cuisines
        +Integer[] occasions
        +Integer[] vibes
        +Integer[] price_ranges
        +Float min_rating
        +Integer[] amenities
        +informed(key) Boolean
        +informed_keys() Symbol[]
        +context() Boolean
        +without(key) Criteria
    }

    class Validation {
        +invalid_fields() String[]
    }

    class Compatibility {
        +score(restaurant) Integer
        +matched_tags(restaurant) String[]
    }

    class Item {
        +Integer compatibility
        +String[] matched_tags
    }

    class Suggestion {
        +String remove
        +Integer would_return
    }

    class Result {
        +String ordering
    }

    City "1" --> "*" Restaurant
    Restaurant "1" --> "*" RestaurantTag
    Tag "1" --> "*" RestaurantTag
    RestaurantSearch --> Criteria : normaliza
    RestaurantSearch --> Validation : valida
    RestaurantSearch --> Compatibility : pontua
    RestaurantSearch --> Result : devolve
    RestaurantSearch ..> SearchHistory : grava
    Result "1" --> "*" Item
    Result "1" --> "0..1" Suggestion
    Item --> Restaurant
    Compatibility --> Criteria
    Validation --> Criteria
```

## Enumerações

| Classe | Enumeração | Valores |
| --- | --- | --- |
| `Restaurant` | `status` | `pending`, `approved`, `rejected` |
| `Tag` | `category` | `cuisine`, `occasion`, `vibe`, `amenity` |
| `Result` | `ordering` | `compatibility`, `rating` |

## Onde cada regra vive

| Regra | Classe e método |
| --- | --- |
| RN-C01 Ignorar critérios não informados | `Criteria.from_params`, `Criteria#informed?` |
| RN-E05 Base elegível | `Restaurant.eligible` |
| RN-C02 Compatibilidade e ordenação | `Compatibility#score`, `RestaurantSearch#sorted` |
| RF23 Selo "Novidade" | `Restaurant#recently_approved?` |
| Fluxo 5c Sugerir critério a remover | `RestaurantSearch#suggestion` |
| RN-C09 Histórico de buscas | `SearchHistory.record` |
| Parâmetro inválido (422) | `Validation#invalid_fields` |

## Simplificação registrada

O grupo decidiu fazer a busca só por filtros, sem API de mapas e sem
geolocalização. Por isso o diagrama não tem o ator secundário de mapas nem
distância: o fluxo 1c (região não reconhecida) não ocorre, e a ordenação do
fluxo 1a usa apenas a nota.
