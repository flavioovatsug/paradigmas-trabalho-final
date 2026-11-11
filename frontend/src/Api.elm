module Api exposing (contar, dica, resolver)

{-| Comunicação com o backend. Cada função devolve um `Cmd msg`: a DESCRIÇÃO
de uma requisição. Quem a executa é o runtime do Elm, que depois chama o
`update` com o resultado embrulhado em `toMsg`.
-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Rainhas exposing (Tabuleiro)


resolver : Tabuleiro -> (Result String Tabuleiro -> msg) -> Cmd msg
resolver =
    post "/api/resolver" (Decode.field "tabuleiro" (Decode.list Decode.int) |> Decode.map Rainhas.deLista)


{-| A API numera linha e coluna a partir de 1; o Elm, a partir de 0.
-}
dica : Tabuleiro -> (Result String ( Int, Int ) -> msg) -> Cmd msg
dica =
    post "/api/dica"
        (Decode.map2 (\l c -> ( l - 1, c - 1 ))
            (Decode.field "linha" Decode.int)
            (Decode.field "coluna" Decode.int)
        )


contar : Tabuleiro -> (Result String Int -> msg) -> Cmd msg
contar =
    post "/api/contar" (Decode.field "total" Decode.int)


{-| Todas as rotas recebem `{"tabuleiro": [...]}`; só muda a URL e o decoder.
As funções acima são esta aplicada parcialmente.
-}
post : String -> Decoder a -> Tabuleiro -> (Result String a -> msg) -> Cmd msg
post url decoder tabuleiro toMsg =
    Http.post
        { url = url
        , body =
            Http.jsonBody
                (Encode.object [ ( "tabuleiro", Encode.list Encode.int (Rainhas.paraLista tabuleiro) ) ])
        , expect = expectJson toMsg decoder
        }


{-| Como `Http.expectJson`, mas lê a mensagem `detail` que o backend manda
nos erros 422, para mostrar na tela.
-}
expectJson : (Result String a -> msg) -> Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.GoodStatus_ _ body ->
                    Decode.decodeString decoder body
                        |> Result.mapError (\_ -> "Resposta inesperada do servidor.")

                Http.BadStatus_ _ body ->
                    Decode.decodeString (Decode.field "detail" Decode.string) body
                        |> Result.withDefault "Erro no servidor."
                        |> Err

                Http.BadUrl_ url ->
                    Err ("URL inválida: " ++ url)

                Http.Timeout_ ->
                    Err "O servidor demorou demais."

                Http.NetworkError_ ->
                    Err "Sem conexão com o servidor. O backend está rodando?"
