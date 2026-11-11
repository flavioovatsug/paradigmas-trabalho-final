module Rainhas exposing
    ( Tabuleiro
    , alternar
    , colocar
    , deLista
    , emConflito
    , paraLista
    , rainhaEm
    , tamanho
    , vazio
    , venceu
    )

{-| Regras do tabuleiro das N-Rainhas. Módulo puro: sem HTTP e sem HTML.

O tabuleiro guarda, para cada linha, `Maybe Int`: `Nothing` se a linha está
vazia, `Just coluna` se há uma rainha nela (colunas começam em 0). Assim é
IMPOSSÍVEL representar duas rainhas na mesma linha.

O tipo é opaco (o construtor `Tabuleiro` não é exportado): fora deste módulo
só se mexe no tabuleiro pelas funções abaixo.

-}


type Tabuleiro
    = Tabuleiro (List (Maybe Int))


vazio : Int -> Tabuleiro
vazio n =
    Tabuleiro (List.repeat n Nothing)


tamanho : Tabuleiro -> Int
tamanho (Tabuleiro linhas) =
    List.length linhas


{-| Coluna da rainha da linha, se houver.
-}
rainhaEm : Int -> Tabuleiro -> Maybe Int
rainhaEm linha (Tabuleiro linhas) =
    linhas
        |> List.drop linha
        |> List.head
        |> Maybe.andThen identity


colocar : Int -> Maybe Int -> Tabuleiro -> Tabuleiro
colocar linha valor (Tabuleiro linhas) =
    Tabuleiro
        (List.indexedMap
            (\i atual ->
                if i == linha then
                    valor

                else
                    atual
            )
            linhas
        )


{-| Clique numa casa: tira a rainha se ela já está ali; senão põe (ou move)
a rainha daquela linha para essa coluna.
-}
alternar : Int -> Int -> Tabuleiro -> Tabuleiro
alternar linha coluna tabuleiro =
    if rainhaEm linha tabuleiro == Just coluna then
        colocar linha Nothing tabuleiro

    else
        colocar linha (Just coluna) tabuleiro


{-| Posições (linha, coluna) de todas as rainhas.
-}
rainhas : Tabuleiro -> List ( Int, Int )
rainhas (Tabuleiro linhas) =
    List.indexedMap (\linha -> Maybe.map (Tuple.pair linha)) linhas
        |> List.filterMap identity


ataca : ( Int, Int ) -> ( Int, Int ) -> Bool
ataca ( l1, c1 ) ( l2, c2 ) =
    l1 /= l2 && (c1 == c2 || abs (l1 - l2) == abs (c1 - c2))


{-| A rainha desta linha é atacada por alguma outra? Calculado aqui (e não
no Prolog) para pintar a casa de vermelho na hora, sem esperar o servidor.
-}
emConflito : Int -> Tabuleiro -> Bool
emConflito linha tabuleiro =
    case rainhaEm linha tabuleiro of
        Nothing ->
            False

        Just coluna ->
            List.any (ataca ( linha, coluna )) (rainhas tabuleiro)


venceu : Tabuleiro -> Bool
venceu tabuleiro =
    let
        postas =
            rainhas tabuleiro
    in
    List.length postas
        == tamanho tabuleiro
        && List.all (\( linha, _ ) -> not (emConflito linha tabuleiro)) postas



-- CONVERSÃO PARA A API
--
-- A API (e o Prolog) usam uma lista de inteiros: coluna de 1 a N, ou 0 para
-- linha vazia.


paraLista : Tabuleiro -> List Int
paraLista (Tabuleiro linhas) =
    List.map (Maybe.map ((+) 1) >> Maybe.withDefault 0) linhas


deLista : List Int -> Tabuleiro
deLista numeros =
    Tabuleiro
        (List.map
            (\n ->
                if n > 0 then
                    Just (n - 1)

                else
                    Nothing
            )
            numeros
        )
