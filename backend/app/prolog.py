"""Ponte entre Python e Prolog usando a biblioteca janus.

O janus roda o SWI-Prolog dentro do processo Python. `query_once` devolve um
dict com as variáveis da consulta e a chave 'truth' (se a consulta deu certo).
Este é o único arquivo que conhece o janus.
"""

from pathlib import Path

import janus_swi as janus

PROLOG_FILE = Path(__file__).parent.parent / "prolog" / "rainhas.pl"
janus.consult(str(PROLOG_FILE))


class SemSolucao(Exception):
    """As rainhas postas não fazem parte de nenhuma solução."""


class Completo(Exception):
    """Todas as linhas já têm rainha: não há dica para dar."""


def resolver(tabuleiro: list[int]) -> list[int]:
    result = janus.query_once("rainhas:resolver(P, S)", {"P": tabuleiro})
    if not result["truth"]:
        raise SemSolucao
    return result["S"]


def contar(tabuleiro: list[int]) -> int:
    return janus.query_once("rainhas:contar_solucoes(P, N)", {"P": tabuleiro})["N"]


def dica(tabuleiro: list[int]) -> tuple[int, int]:
    # dica/2 devolve [Linha, Coluna] ou os átomos completo/impossivel
    # (átomos chegam ao Python como strings).
    match janus.query_once("rainhas:dica(P, D)", {"P": tabuleiro})["D"]:
        case "completo":
            raise Completo
        case "impossivel":
            raise SemSolucao
        case [linha, coluna]:
            return linha, coluna
    raise ValueError("resultado inesperado de dica/2")
