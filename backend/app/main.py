"""API HTTP das N-Rainhas. Só recebe JSON, chama o Prolog e devolve JSON.

Rodar: uv run fastapi dev app/main.py  (documentação em /docs)
"""

from typing import Annotated

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app import prolog

app = FastAPI(title="N-Rainhas (Prolog + Elm)")

# Tabuleiro de 4 a 8 linhas; cada número é a coluna da rainha (1..8) ou 0.
Casa = Annotated[int, Field(ge=0, le=8)]
Tabuleiro = Annotated[list[Casa], Field(min_length=4, max_length=8)]

SEM_SOLUCAO = "Essas rainhas não levam a nenhuma solução. Tire alguma."
COMPLETO = "O tabuleiro já está completo."


class TabuleiroRequest(BaseModel):
    tabuleiro: Tabuleiro


class TabuleiroResponse(BaseModel):
    tabuleiro: Tabuleiro


class DicaResponse(BaseModel):
    linha: int
    coluna: int


class ContagemResponse(BaseModel):
    total: int


@app.post("/api/resolver")
def resolver(req: TabuleiroRequest) -> TabuleiroResponse:
    try:
        return TabuleiroResponse(tabuleiro=prolog.resolver(req.tabuleiro))
    except prolog.SemSolucao:
        raise HTTPException(status_code=422, detail=SEM_SOLUCAO) from None


@app.post("/api/dica")
def dica(req: TabuleiroRequest) -> DicaResponse:
    try:
        linha, coluna = prolog.dica(req.tabuleiro)
    except prolog.SemSolucao:
        raise HTTPException(status_code=422, detail=SEM_SOLUCAO) from None
    except prolog.Completo:
        raise HTTPException(status_code=422, detail=COMPLETO) from None
    return DicaResponse(linha=linha, coluna=coluna)


@app.post("/api/contar")
def contar(req: TabuleiroRequest) -> ContagemResponse:
    return ContagemResponse(total=prolog.contar(req.tabuleiro))
