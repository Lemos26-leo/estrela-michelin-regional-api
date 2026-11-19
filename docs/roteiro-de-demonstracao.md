# Roteiro de demonstração — UC-C04

Dez minutos, mostrando o fluxo principal e as duas exceções. Os ids abaixo
são os do `db/seeds.rb` recém-rodado.

## Antes de começar

```bash
# no repositório da API: sobe o PostgreSQL e a API na porta 3000
docker compose up -d

# no repositório do front, em outro terminal: Vite na porta 5173
docker compose up -d
```

Abra `http://localhost:5173`. Deixe `http://localhost:3000/up` aberto numa
aba para mostrar que a API está no ar.

## 1. Fluxo principal

1. **Informar critérios.** Cidade **Maringá**, ocasião **Jantar
   romântico**, vibe **Aconchegante**, culinária **Italiana**, preço **$$**,
   nota mínima **4,0 ou mais**. Toque em **Buscar restaurantes**.
2. **Compatibilidade e ordenação (RN-C02).** A lista traz a *Cantina da
   Nonna* com **100%**, a *Casa Tulipa* com **68%** e a *Forneria 44* com
   **40%**, nessa ordem. Vale explicar a Casa Tulipa: ela não é italiana e
   está na faixa vizinha de preço, por isso perde pontos de culinária e de
   preço, mas ganha os de ocasião e vibe.
3. **Tags coincidentes e selo "Novidade" (RF23).** Cada cartão mostra as
   tags que pontuaram. A Cantina da Nonna, aprovada há 12 dias, traz o selo
   **Novidade**.
4. **Critérios não informados são ignorados (RN-C01).** Volte a cidade para
   **Todas as cidades**: a lista vai de 3 para 7 restaurantes, com a
   *Osteria Fiore* de Curitiba em segundo lugar, com 93%. Nenhum outro
   filtro mudou.
5. **Refinar (fluxo 5a).** Volte a cidade para Maringá e troque a vibe para
   **Elegante**: a URL muda e a busca refaz sozinha. A ordem muda — a
   Cantina da Nonna cai para 70%, porque é aconchegante e não elegante, e o
   *Sushi Hanako* entra com 68%. Mostre que a URL pode ser copiada e
   reaberta.
6. **Abrir o restaurante.** Clique no nome: cai no placeholder do UC-C06.

## 2. Exceção 1a — sem ocasião nem vibe

Desmarque ocasião e vibe, volte a cidade para **Todas as cidades** e deixe
só a culinária **Italiana**. A lista passa a dizer **Ordenado por nota**, o
percentual de compatibilidade desaparece dos cartões e *Madeira e Brasa*
(4,8) vem primeiro — mesmo não sendo italiana, porque culinária não elimina
ninguém, só pesa.

Vale registrar aqui a simplificação do grupo: o caso de uso fala em
proximidade, mas a busca é só por filtros, sem API de mapas nem
geolocalização.

## 3. Exceção 5c — nenhum resultado

Cidade **Maringá**, ocasião **Jantar romântico**, vibe **Aconchegante** e
comodidade **Área externa**. A tela mostra "Nenhum restaurante combina com
tudo isso" e o botão **Remover comodidades**, dizendo que 3 restaurantes
voltam. Toque no botão: a busca refaz sem o critério.

A sugestão é sempre o critério que devolve mais restaurantes, não um
critério fixo: acrescente também a nota mínima **4,5 ou mais**, a culinária
**Italiana** e o preço **$$**, e a sugestão passa a ser **Remover nota
mínima**.

## 4. Base elegível (RN-E05)

Mostre no `db/seeds.rb` os cinco restaurantes que nunca aparecem na lista:
*Alto da Serra* (pendente), *Sabor Antigo* (reprovado), *Bistrô do Largo*
(sem vibe), *Cozinha da Vila* (sem ocasião) e *Cantina Provisória* (sem
faixa de preço). Em seguida:

```bash
docker compose exec rails bin/rails runner "puts Restaurant.count; puts Restaurant.eligible.count"
# 28
# 23
```

## 5. Histórico (RN-C09)

O front manda o cabeçalho `X-Client-Id` em cada busca. Mostre o que ficou
gravado:

```bash
docker compose exec rails bin/rails runner "pp SearchHistory.most_recent_first.limit(3).pluck(:client_id, :criteria)"
```

E, sem o cabeçalho, nada é gravado:

```bash
curl "http://localhost:3000/api/v1/restaurants/search?occasions[]=8"
```

## 6. Parâmetro inválido

```bash
curl -i "http://localhost:3000/api/v1/restaurants/search?city_id=999&price_ranges[]=9"
# HTTP/1.1 422
# {"error":"invalid_params","fields":["city_id","price_ranges"]}
```

## 7. Testes

```bash
docker compose exec rails bin/rails test
# 41 runs, 109 assertions, 0 failures, 0 errors
```

Abra `test/services/restaurant_search_test.rb` e mostre que há um teste por
regra: critério em branco, base elegível, ordem por compatibilidade, ordem
por nota, selo aos 29 e aos 31 dias, sugestão no resultado vazio e
histórico limitado a 50.
