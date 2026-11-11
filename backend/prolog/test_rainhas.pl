/*  test_rainhas.pl: testes plunit de rainhas.pl.

    Rodar:  swipl -g run_tests -t halt backend/prolog/test_rainhas.pl
*/

:- use_module(rainhas).
:- use_module(library(plunit)).
:- use_module(library(lists)).

:- begin_tests(resolver).

test(quatro_por_quatro, true(S == [2, 4, 1, 3])) :-
    resolver([0, 0, 0, 0], S).

test(mantem_rainhas_postas, true(Primeira == 3)) :-
    resolver([3, 0, 0, 0, 0, 0, 0, 0], [Primeira | _]).

test(rainhas_na_mesma_coluna, fail) :-
    resolver([1, 1, 0, 0], _).

test(rainhas_na_mesma_diagonal, fail) :-
    resolver([1, 2, 0, 0, 0], _).

test(tres_por_tres_nao_tem_solucao, fail) :-
    resolver([0, 0, 0], _).

:- end_tests(resolver).

:- begin_tests(contar).

test(quatro, true(N == 2)) :-
    contar_solucoes([0, 0, 0, 0], N).

test(oito, true(N == 92)) :-
    contar_solucoes([0, 0, 0, 0, 0, 0, 0, 0], N).

test(parcial_impossivel, true(N == 0)) :-
    contar_solucoes([1, 1, 0, 0], N).

:- end_tests(contar).

:- begin_tests(dica).

test(primeira_linha_vazia, true(D == [2, 4])) :-
    dica([2, 0, 0, 0], D).

test(completo, true(D == completo)) :-
    dica([2, 4, 1, 3], D).

test(impossivel, true(D == impossivel)) :-
    dica([1, 1, 0, 0], D).

:- end_tests(dica).
