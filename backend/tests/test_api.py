"""Testes da API (pytest). As regras do jogo são testadas em Prolog;
aqui conferimos só rotas, JSON e códigos de status."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)
VAZIO_4 = [0, 0, 0, 0]


def test_resolver():
    r = client.post("/api/resolver", json={"tabuleiro": VAZIO_4})
    assert r.status_code == 200
    assert r.json()["tabuleiro"] == [2, 4, 1, 3]


def test_resolver_sem_solucao():
    r = client.post("/api/resolver", json={"tabuleiro": [1, 1, 0, 0]})
    assert r.status_code == 422
    assert "nenhuma solução" in r.json()["detail"]


def test_tabuleiro_malformado():
    r = client.post("/api/resolver", json={"tabuleiro": [0, 0]})
    assert r.status_code == 422


def test_dica():
    r = client.post("/api/dica", json={"tabuleiro": [2, 0, 0, 0]})
    assert r.json() == {"linha": 2, "coluna": 4}


def test_dica_completo():
    r = client.post("/api/dica", json={"tabuleiro": [2, 4, 1, 3]})
    assert r.status_code == 422
    assert r.json()["detail"] == "O tabuleiro já está completo."


def test_contar():
    r = client.post("/api/contar", json={"tabuleiro": [0] * 8})
    assert r.json() == {"total": 92}
