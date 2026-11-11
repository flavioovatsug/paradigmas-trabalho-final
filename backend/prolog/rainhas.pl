/*  rainhas.pl: o problema das N-Rainhas com CLP(FD).

    Colocar N rainhas num tabuleiro N x N sem que nenhuma ataque outra
    (mesma linha, coluna ou diagonal).

    REPRESENTAÇÃO
    Um tabuleiro é uma lista com N números, um por linha. O número da
    linha I é a coluna (1..N) da rainha daquela linha, ou 0 se a linha
    ainda está vazia. Exemplo 4x4: [2, 4, 1, 3] é uma solução completa;
    [2, 0, 0, 0] tem só a rainha da primeira linha.

    Como cada linha guarda UMA coluna, é impossível ter duas rainhas na
    mesma linha: essa regra vem de graça da representação.

    Testar no terminal:
        $ swipl backend/prolog/rainhas.pl
        ?- resolver([0,0,0,0,0,0,0,0], S).
        ?- contar_solucoes([0,0,0,0,0,0,0,0], N).    % N = 92
*/

:- module(rainhas, [resolver/2, contar_solucoes/2, dica/2]).

:- use_module(library(clpfd)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(aggregate)).

%!  solucao(+Parcial, -Rainhas) is nondet.
%
%   Rainhas é uma solução completa que mantém as rainhas já postas em
%   Parcial. No backtracking, devolve cada uma das outras soluções.
%   Primeiro DESCREVEMOS as regras (restricoes/2) e só depois pedimos ao
%   CLP(FD) que busque valores (labeling/2).
solucao(Parcial, Rainhas) :-
    restricoes(Parcial, Rainhas),
    labeling([ff], Rainhas).

%!  restricoes(+Parcial, -Rainhas) is det.
%
%   Cria uma variável por linha e declara o que uma solução precisa
%   satisfazer. Nenhuma busca acontece aqui.
restricoes(Parcial, Rainhas) :-
    length(Parcial, N),
    length(Rainhas, N),
    Rainhas ins 1..N,                     % cada rainha numa coluna válida
    maplist(manter_rainha, Parcial, Rainhas),
    all_distinct(Rainhas),                % colunas diferentes
    diagonais_livres(Rainhas).

%   Uma casa vazia (0) não restringe nada; uma rainha já posta fixa a coluna.
manter_rainha(0, _).
manter_rainha(Coluna, Rainha) :-
    Coluna #> 0,
    Rainha #= Coluna.

%   Nenhum par de rainhas na mesma diagonal. Duas rainhas a D linhas de
%   distância estão na mesma diagonal se as colunas também diferem de D.
diagonais_livres([]).
diagonais_livres([Rainha | Abaixo]) :-
    nao_ataca(Rainha, Abaixo, 1),
    diagonais_livres(Abaixo).

nao_ataca(_, [], _).
nao_ataca(Rainha, [Outra | Resto], Distancia) :-
    abs(Rainha - Outra) #\= Distancia,
    Proxima is Distancia + 1,
    nao_ataca(Rainha, Resto, Proxima).

%!  resolver(+Parcial, -Solucao) is semidet.
%
%   A primeira solução que completa Parcial. Falha se não houver nenhuma.
resolver(Parcial, Solucao) :-
    once(solucao(Parcial, Solucao)).

%!  contar_solucoes(+Parcial, -Total) is det.
%
%   Quantas soluções completam Parcial. aggregate_all/3 força o
%   backtracking por TODAS as respostas de solucao/2 e conta.
contar_solucoes(Parcial, Total) :-
    aggregate_all(count, solucao(Parcial, _), Total).

%!  dica(+Parcial, -Dica) is det.
%
%   Dica é [Linha, Coluna] (ambos a partir de 1) com uma rainha que leva
%   a uma solução, ou o átomo `completo`, ou o átomo `impossivel` quando
%   as rainhas postas não cabem em nenhuma solução.
dica(Parcial, Dica) :-
    (   resolver(Parcial, Solucao)
    ->  (   nth1(Linha, Parcial, 0)       % primeira linha vazia
        ->  nth1(Linha, Solucao, Coluna),
            Dica = [Linha, Coluna]
        ;   Dica = completo
        )
    ;   Dica = impossivel
    ).
