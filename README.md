# N-Rainhas em Prolog + Elm

Trabalho final de Paradigmas de Programação. Um site onde se joga o
quebra-cabeça das N-Rainhas: pôr N rainhas num tabuleiro N x N sem que
nenhuma ataque outra. O Prolog resolve, dá dicas e conta soluções; o Elm
desenha a interface; o Python só faz a ponte entre os dois.

```
Navegador (Elm) --HTTP/JSON--> FastAPI (Python) --janus--> SWI-Prolog
frontend/src/                  backend/app/                backend/prolog/
```

## Requisitos

- [SWI-Prolog](https://www.swi-prolog.org/Download.html) 9.2 ou mais novo (`swipl` no PATH);
- [uv](https://docs.astral.sh/uv/) (instala o Python sozinho);
- [Node.js](https://nodejs.org) 20 ou mais novo.

## Como rodar

```sh
make install    # uma vez só
make dev        # sobe backend (8000) e frontend (5173)
```

Abra http://localhost:5173.

## Testes

```sh
make test       # plunit (Prolog) + pytest (API)
```

## Como jogar

- Clique numa casa para pôr uma rainha. Cada linha tem no máximo uma rainha:
  clicar em outra casa da mesma linha move a rainha; clicar nela de novo tira.
- Rainhas que se atacam ficam vermelhas.
- **Dica**: o Prolog põe uma rainha correta na primeira linha vazia.
- **Resolver**: o Prolog completa o tabuleiro mantendo as suas rainhas.
- **Contar soluções**: quantas soluções existem com as rainhas já postas
  (92 no 8x8 vazio).

## API

O tabuleiro é uma lista com um número por linha: a coluna da rainha (1..N)
ou 0 se a linha está vazia. N vai de 4 a 8.

| Rota                 | Corpo                         | Resposta                     |
| -------------------- | ----------------------------- | ---------------------------- |
| `POST /api/resolver` | `{"tabuleiro": [0,0,0,0]}`    | `{"tabuleiro": [2,4,1,3]}`   |
| `POST /api/dica`     | `{"tabuleiro": [2,0,0,0]}`    | `{"linha": 2, "coluna": 4}`  |
| `POST /api/contar`   | `{"tabuleiro": [0,0,0,0]}`    | `{"total": 2}`               |

Sem solução (ou tabuleiro completo, na dica) a resposta é 422 com
`{"detail": "mensagem"}`, que o Elm mostra na tela.

## Prolog direto no terminal

```
$ swipl backend/prolog/rainhas.pl
?- resolver([0,0,0,0,0,0,0,0], S).
?- contar_solucoes([0,0,0,0,0,0,0,0], N).
?- dica([1,0,0,0,0], D).
```

## Estrutura

```
backend/prolog/rainhas.pl        regras (CLP(FD)), resolver, contar, dica
backend/prolog/test_rainhas.pl   testes plunit
backend/app/prolog.py            ponte Python -> Prolog (janus)
backend/app/main.py              rotas HTTP
backend/tests/test_api.py        testes da API
frontend/src/Rainhas.elm         tipo do tabuleiro e regras (puro)
frontend/src/Api.elm             HTTP e JSON
frontend/src/Main.elm            Model, Msg, update, view
frontend/src/style.css           visual (Tailwind + daisyUI)
```

## Problema comum

`ImportError: libswipl...` ao subir o backend: o `janus-swi` foi compilado
para outra versão do SWI-Prolog. Recompile:

```sh
cd backend
uv sync --reinstall-package janus-swi --no-binary-package janus-swi --no-cache
```
