module Main exposing (main)

{-| Tela do jogo, na Arquitetura Elm: Model, Msg, update e view.
-}

import Api
import Browser
import Html exposing (Html, button, div, h1, p, text)
import Html.Attributes exposing (class, classList, disabled, style)
import Html.Events exposing (onClick)
import Rainhas exposing (Tabuleiro)


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( novo 8, Cmd.none )
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { tabuleiro : Tabuleiro
    , status : Status
    }


{-| Um custom type em vez de vários campos soltos (`carregando : Bool`,
`erro : Maybe String`...): só um estado vale por vez.
-}
type Status
    = Jogando
    | Esperando
    | Aviso String
    | Falha String


novo : Int -> Model
novo n =
    { tabuleiro = Rainhas.vazio n, status = Jogando }



-- UPDATE


type Msg
    = Clicou Int Int
    | MudouTamanho Int
    | Limpou
    | PediuDica
    | PediuSolucao
    | PediuContagem
    | RecebeuDica (Result String ( Int, Int ))
    | RecebeuSolucao (Result String Tabuleiro)
    | RecebeuContagem (Result String Int)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Clicou linha coluna ->
            ( { model | tabuleiro = Rainhas.alternar linha coluna model.tabuleiro, status = Jogando }, Cmd.none )

        MudouTamanho n ->
            ( novo n, Cmd.none )

        Limpou ->
            ( novo (Rainhas.tamanho model.tabuleiro), Cmd.none )

        PediuDica ->
            ( { model | status = Esperando }, Api.dica model.tabuleiro RecebeuDica )

        PediuSolucao ->
            ( { model | status = Esperando }, Api.resolver model.tabuleiro RecebeuSolucao )

        PediuContagem ->
            ( { model | status = Esperando }, Api.contar model.tabuleiro RecebeuContagem )

        RecebeuDica (Ok ( linha, coluna )) ->
            ( { model
                | tabuleiro = Rainhas.colocar linha (Just coluna) model.tabuleiro
                , status = Aviso ("Dica: rainha na linha " ++ String.fromInt (linha + 1) ++ ".")
              }
            , Cmd.none
            )

        RecebeuSolucao (Ok tabuleiro) ->
            ( { model | tabuleiro = tabuleiro, status = Aviso "O Prolog completou o tabuleiro." }, Cmd.none )

        RecebeuContagem (Ok total) ->
            ( { model | status = Aviso (textoContagem total) }, Cmd.none )

        RecebeuDica (Err erro) ->
            ( { model | status = Falha erro }, Cmd.none )

        RecebeuSolucao (Err erro) ->
            ( { model | status = Falha erro }, Cmd.none )

        RecebeuContagem (Err erro) ->
            ( { model | status = Falha erro }, Cmd.none )


textoContagem : Int -> String
textoContagem total =
    case total of
        0 ->
            "Nenhuma solução contém essas rainhas."

        1 ->
            "Há exatamente 1 solução com essas rainhas."

        _ ->
            "Há " ++ String.fromInt total ++ " soluções com essas rainhas."



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ h1 [ class "titulo" ] [ text "♛ N-Rainhas" ]
        , p [ class "subtitulo" ] [ text "Ponha uma rainha por linha sem que nenhuma ataque outra." ]
        , viewTamanhos (Rainhas.tamanho model.tabuleiro)
        , viewTabuleiro model.tabuleiro
        , viewBotoes model.status
        , viewStatus model
        ]


viewTamanhos : Int -> Html Msg
viewTamanhos atual =
    div [ class "join" ]
        (List.map
            (\n ->
                button
                    [ class "btn btn-sm join-item"
                    , classList [ ( "btn-primary", n == atual ) ]
                    , onClick (MudouTamanho n)
                    ]
                    [ text (String.fromInt n ++ "×" ++ String.fromInt n) ]
            )
            (List.range 4 8)
        )


viewTabuleiro : Tabuleiro -> Html Msg
viewTabuleiro tabuleiro =
    let
        n =
            Rainhas.tamanho tabuleiro

        indices =
            List.range 0 (n - 1)
    in
    div
        [ class "tabuleiro"
        , style "grid-template-columns" ("repeat(" ++ String.fromInt n ++ ", 3rem)")
        ]
        (List.concatMap (\linha -> List.map (viewCasa tabuleiro linha) indices) indices)


viewCasa : Tabuleiro -> Int -> Int -> Html Msg
viewCasa tabuleiro linha coluna =
    let
        temRainha =
            Rainhas.rainhaEm linha tabuleiro == Just coluna
    in
    button
        [ class "casa"
        , classList
            [ ( "casa--escura", modBy 2 (linha + coluna) == 1 )
            , ( "casa--conflito", temRainha && Rainhas.emConflito linha tabuleiro )
            ]
        , onClick (Clicou linha coluna)
        ]
        [ text
            (if temRainha then
                "♛"

             else
                ""
            )
        ]


viewBotoes : Status -> Html Msg
viewBotoes status =
    let
        botao rotulo msg =
            button [ class "btn btn-sm", disabled (status == Esperando), onClick msg ] [ text rotulo ]
    in
    div [ class "botoes" ]
        [ botao "Dica" PediuDica
        , botao "Resolver" PediuSolucao
        , botao "Contar soluções" PediuContagem
        , botao "Limpar" Limpou
        ]


viewStatus : Model -> Html Msg
viewStatus model =
    if Rainhas.venceu model.tabuleiro then
        div [ class "alert alert-success" ] [ text "Parabéns! Nenhuma rainha se ataca." ]

    else
        case model.status of
            Jogando ->
                text ""

            Esperando ->
                div [ class "alert" ] [ text "Perguntando ao Prolog..." ]

            Aviso mensagem ->
                div [ class "alert alert-info" ] [ text mensagem ]

            Falha mensagem ->
                div [ class "alert alert-error" ] [ text mensagem ]
