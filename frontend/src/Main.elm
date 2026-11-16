port module Main exposing (main)

{-| Tela do jogo, na Arquitetura Elm: Model, Msg, update e view.
-}

import Api
import Browser
import Browser.Events
import Html exposing (Html, button, div, h1, h2, p, span, strong, text)
import Html.Attributes exposing (attribute, class, classList, disabled, id, style)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Rainhas exposing (Tabuleiro)


port marcarAjudaVista : () -> Cmd msg


type alias Flags =
    { mostrarAjuda : Bool
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = \flags -> ( novo 8 True flags.mostrarAjuda, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.mostrarAjuda then
        Browser.Events.onKeyDown
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\tecla ->
                        if tecla == "Escape" then
                            Decode.succeed FechouAjuda

                        else
                            Decode.fail "outra tecla"
                    )
            )

    else
        Sub.none



-- MODEL


type alias Model =
    { tabuleiro : Tabuleiro
    , status : Status
    , mostrarAmeacas : Bool
    , ultimaDica : Maybe ( Int, Int )
    , mostrarAjuda : Bool
    }


{-| Um custom type em vez de vários campos soltos (`carregando : Bool`,
`erro : Maybe String`...): só um estado vale por vez.
-}
type Status
    = Jogando
    | Esperando
    | Aviso String
    | Falha String


novo : Int -> Bool -> Bool -> Model
novo n mostrarAmeacas mostrarAjuda =
    { tabuleiro = Rainhas.vazio n
    , status = Jogando
    , mostrarAmeacas = mostrarAmeacas
    , ultimaDica = Nothing
    , mostrarAjuda = mostrarAjuda
    }



-- UPDATE


type Msg
    = Clicou Int Int
    | MudouTamanho Int
    | AlternouAmeacas
    | AbriuAjuda
    | FechouAjuda
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
            ( { model
                | tabuleiro = Rainhas.alternar linha coluna model.tabuleiro
                , status = Jogando
                , ultimaDica = Nothing
              }
            , Cmd.none
            )

        MudouTamanho n ->
            ( novo n model.mostrarAmeacas model.mostrarAjuda, Cmd.none )

        AlternouAmeacas ->
            ( { model | mostrarAmeacas = not model.mostrarAmeacas }, Cmd.none )

        AbriuAjuda ->
            ( { model | mostrarAjuda = True }, Cmd.none )

        FechouAjuda ->
            ( { model | mostrarAjuda = False }, marcarAjudaVista () )

        Limpou ->
            ( novo (Rainhas.tamanho model.tabuleiro) model.mostrarAmeacas model.mostrarAjuda, Cmd.none )

        PediuDica ->
            ( { model | status = Esperando }, Api.dica model.tabuleiro RecebeuDica )

        PediuSolucao ->
            ( { model | status = Esperando, ultimaDica = Nothing }, Api.resolver model.tabuleiro RecebeuSolucao )

        PediuContagem ->
            ( { model | status = Esperando }, Api.contar model.tabuleiro RecebeuContagem )

        RecebeuDica (Ok ( linha, coluna )) ->
            ( { model
                | tabuleiro = Rainhas.colocar linha (Just coluna) model.tabuleiro
                , status = Aviso ("Dica: rainha colocada na casa " ++ nomeCasa linha coluna ++ ".")
                , ultimaDica = Just ( linha, coluna )
              }
            , Cmd.none
            )

        RecebeuSolucao (Ok tabuleiro) ->
            ( { model
                | tabuleiro = tabuleiro
                , status = Aviso "O Prolog completou o tabuleiro."
                , ultimaDica = Nothing
              }
            , Cmd.none
            )

        RecebeuContagem (Ok total) ->
            ( { model | status = Aviso (textoContagem total) }, Cmd.none )

        RecebeuDica (Err erro) ->
            ( { model | status = Falha erro }, Cmd.none )

        RecebeuSolucao (Err erro) ->
            ( { model | status = Falha erro }, Cmd.none )

        RecebeuContagem (Err erro) ->
            ( { model | status = Falha erro }, Cmd.none )


nomeCasa : Int -> Int -> String
nomeCasa linha coluna =
    letraColuna coluna ++ String.fromInt (linha + 1)


letraColuna : Int -> String
letraColuna coluna =
    String.fromChar (Char.fromCode (65 + coluna))


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
    div [ class "pagina" ]
        [ div [ class "painel" ]
            [ viewCabecalho
            , viewControles (Rainhas.tamanho model.tabuleiro) model.mostrarAmeacas
            , viewHud model.tabuleiro
            , viewTabuleiro model
            , viewBotoes model.status (Rainhas.totalRainhas model.tabuleiro == 0)
            , viewStatus model
            ]
        , if model.mostrarAjuda then
            viewModalAjuda (Rainhas.tamanho model.tabuleiro)

          else
            text ""
        ]


viewCabecalho : Html Msg
viewCabecalho =
    div [ class "cabecalho" ]
        [ span [ class "selo-tech" ] [ text "Prolog CLP(FD) · Elm" ]
        , div [ class "titulo-linha" ]
            [ span [ class "titulo-emblema", attribute "aria-hidden" "true" ]
                [ span [ class "rainha-icone rainha-icone--titulo" ] [] ]
            , h1 [ class "titulo" ] [ text "N-Rainhas" ]
            ]
        , p [ class "subtitulo" ] [ text "Ponha uma rainha por linha sem que nenhuma ataque outra." ]
        ]


viewControles : Int -> Bool -> Html Msg
viewControles atual mostrarAmeacas =
    div [ class "controles" ]
        [ div [ class "seletor-tamanho", attribute "role" "group", attribute "aria-label" "Tamanho do tabuleiro" ]
            (List.map
                (\n ->
                    button
                        [ class "tamanho-btn"
                        , classList [ ( "tamanho-btn--ativo", n == atual ) ]
                        , onClick (MudouTamanho n)
                        ]
                        [ text (String.fromInt n ++ "×" ++ String.fromInt n) ]
                )
                (List.range 4 8)
            )
        , button
            [ class "ameacas-toggle"
            , classList [ ( "ameacas-toggle--ativo", mostrarAmeacas ) ]
            , attribute "aria-pressed"
                (if mostrarAmeacas then
                    "true"

                 else
                    "false"
                )
            , onClick AlternouAmeacas
            ]
            [ span [ class "icone icone--olho", attribute "aria-hidden" "true" ] []
            , span [] [ text "Ameaças" ]
            ]
        , button
            [ class "ajuda-btn"
            , attribute "aria-label" "Como jogar"
            , attribute "title" "Como jogar"
            , onClick AbriuAjuda
            ]
            [ text "?" ]
        ]


viewHud : Tabuleiro -> Html Msg
viewHud tabuleiro =
    let
        n =
            Rainhas.tamanho tabuleiro

        postas =
            Rainhas.totalRainhas tabuleiro

        conflitos =
            Rainhas.totalConflitos tabuleiro

        venceu =
            Rainhas.venceu tabuleiro

        progressoPct =
            String.fromInt (round (toFloat postas / toFloat n * 100)) ++ "%"

        ( estadoTexto, estadoClasse ) =
            if venceu then
                ( "Solução completa!", "hud-estado--vitoria" )

            else if conflitos > 0 then
                ( String.fromInt conflitos ++ " em conflito", "hud-estado--conflito" )

            else if postas == 0 then
                ( "Toque numa casa", "hud-estado--neutro" )

            else
                ( "Sem conflitos", "hud-estado--ok" )
    in
    div [ class "hud" ]
        [ div [ class "hud-topo" ]
            [ span [ class "hud-contador" ]
                [ text (String.fromInt postas ++ " / " ++ String.fromInt n ++ " rainhas") ]
            , span [ class ("hud-estado " ++ estadoClasse) ] [ text estadoTexto ]
            ]
        , div [ class "progresso-trilha" ]
            [ div
                [ class "progresso-barra"
                , classList
                    [ ( "progresso-barra--conflito", conflitos > 0 )
                    , ( "progresso-barra--vitoria", venceu )
                    ]
                , style "width" progressoPct
                ]
                []
            ]
        ]


viewTabuleiro : Model -> Html Msg
viewTabuleiro model =
    let
        n =
            Rainhas.tamanho model.tabuleiro

        indices =
            List.range 0 (n - 1)

        venceu =
            Rainhas.venceu model.tabuleiro
    in
    div [ class "moldura-externa" ]
        [ div
            [ class "moldura"
            , classList [ ( "moldura--vitoria", venceu ) ]
            , attribute "data-n" (String.fromInt n)
            ]
            [ if venceu then
                div [ class "confetes", attribute "aria-hidden" "true" ]
                    (List.repeat 14 (span [ class "confete" ] []))

              else
                text ""
            , div [ class "grade-com-coordenadas" ]
                [ div
                    [ class "coord-linhas"
                    , attribute "aria-hidden" "true"
                    , style "grid-template-rows" ("repeat(" ++ String.fromInt n ++ ", var(--casa-tam))")
                    ]
                    (List.map (\l -> span [ class "coord-item" ] [ text (String.fromInt (l + 1)) ]) indices)
                , div [ class "tabuleiro-coluna" ]
                    [ div
                        [ class "tabuleiro"
                        , style "grid-template-columns" ("repeat(" ++ String.fromInt n ++ ", var(--casa-tam))")
                        ]
                        (List.concatMap (\linha -> List.map (viewCasa model venceu linha) indices) indices)
                    , div
                        [ class "coord-colunas"
                        , attribute "aria-hidden" "true"
                        , style "grid-template-columns" ("repeat(" ++ String.fromInt n ++ ", var(--casa-tam))")
                        ]
                        (List.map (\c -> span [ class "coord-item" ] [ text (letraColuna c) ]) indices)
                    ]
                ]
            ]
        ]


viewCasa : Model -> Bool -> Int -> Int -> Html Msg
viewCasa model venceu linha coluna =
    let
        temRainha =
            Rainhas.rainhaEm linha model.tabuleiro == Just coluna

        conflito =
            temRainha && Rainhas.emConflito linha model.tabuleiro

        atacada =
            not temRainha
                && not venceu
                && model.mostrarAmeacas
                && Rainhas.estaAtacada ( linha, coluna ) model.tabuleiro

        dicaRecente =
            model.ultimaDica == Just ( linha, coluna )
    in
    button
        [ class "casa"
        , classList
            [ ( "casa--escura", modBy 2 (linha + coluna) == 1 )
            , ( "casa--conflito", conflito )
            , ( "casa--vitoria", venceu && temRainha )
            , ( "casa--dica", dicaRecente )
            , ( "casa--atacada", atacada )
            ]
        , attribute "data-linha" (String.fromInt linha)
        , attribute "aria-label" ("Casa " ++ nomeCasa linha coluna)
        , onClick (Clicou linha coluna)
        ]
        [ if temRainha then
            span [ class "rainha-wrap" ]
                [ span [ class "rainha-icone", attribute "aria-hidden" "true" ] [] ]

          else
            span [ class "rainha-fantasma", attribute "aria-hidden" "true" ] []
        ]


viewBotoes : Status -> Bool -> Html Msg
viewBotoes status vazio =
    let
        esperando =
            status == Esperando

        botao classeExtra icone rotulo desabilitado msg =
            button
                [ class ("acao-btn " ++ classeExtra)
                , disabled (esperando || desabilitado)
                , onClick msg
                ]
                [ span [ class ("icone " ++ icone), attribute "aria-hidden" "true" ] []
                , span [] [ text rotulo ]
                ]
    in
    div [ class "botoes" ]
        [ botao "acao-btn--primario" "icone--dica" "Dica" False PediuDica
        , botao "acao-btn--secundario" "icone--resolver" "Resolver" False PediuSolucao
        , botao "acao-btn--neutro" "icone--contar" "Contar soluções" False PediuContagem
        , botao "acao-btn--sutil" "icone--limpar" "Limpar" vazio Limpou
        ]


viewStatus : Model -> Html Msg
viewStatus model =
    div [ class "status-area" ]
        [ if Rainhas.venceu model.tabuleiro then
            div [ class "status-banner status-banner--vitoria" ]
                [ span [ class "icone icone--trofeu", attribute "aria-hidden" "true" ] []
                , span [] [ text "Parabéns! Nenhuma rainha se ataca." ]
                ]

          else
            case model.status of
                Jogando ->
                    p [ class "status-dica-uso" ]
                        [ text "Clique em outra casa da mesma linha para mover, ou na mesma para remover." ]

                Esperando ->
                    div [ class "status-banner status-banner--carregando" ]
                        [ span [ class "spinner", attribute "aria-hidden" "true" ] []
                        , span [] [ text "Perguntando ao Prolog..." ]
                        ]

                Aviso mensagem ->
                    div [ class "status-banner status-banner--aviso" ]
                        [ span [ class "icone icone--info", attribute "aria-hidden" "true" ] []
                        , span [] [ text mensagem ]
                        ]

                Falha mensagem ->
                    div [ class "status-banner status-banner--falha" ]
                        [ span [ class "icone icone--alerta", attribute "aria-hidden" "true" ] []
                        , span [] [ text mensagem ]
                        ]
        ]


viewModalAjuda : Int -> Html Msg
viewModalAjuda n =
    div
        [ class "modal-fundo"
        , attribute "role" "dialog"
        , attribute "aria-modal" "true"
        , attribute "aria-labelledby" "titulo-ajuda"
        ]
        [ div [ class "modal-overlay", onClick FechouAjuda ] []
        , div [ class "modal-cartao" ]
            [ div [ class "modal-topo" ]
                [ div [ class "modal-titulo-wrap" ]
                    [ span [ class "titulo-emblema titulo-emblema--menor", attribute "aria-hidden" "true" ]
                        [ span [ class "rainha-icone rainha-icone--modal" ] [] ]
                    , h2 [ id "titulo-ajuda", class "modal-titulo" ] [ text "Como jogar N-Rainhas" ]
                    ]
                , button
                    [ class "modal-fechar"
                    , attribute "aria-label" "Fechar"
                    , onClick FechouAjuda
                    ]
                    [ text "×" ]
                ]
            , div [ class "modal-objetivo" ]
                [ strong [ class "modal-objetivo-titulo" ] [ text "Objetivo do jogo" ]
                , p [ class "modal-objetivo-texto" ]
                    [ text "Você vence quando colocar "
                    , strong [] [ text (String.fromInt n ++ " rainhas") ]
                    , text (" (1 em cada linha do tabuleiro " ++ String.fromInt n ++ "×" ++ String.fromInt n ++ ") sem que nenhuma ataque outra.")
                    ]
                ]
            , div [ class "modal-exemplo" ]
                [ viewMiniTabuleiro
                , div [ class "modal-regra" ]
                    [ p [ class "modal-regra-titulo" ] [ text "Como uma rainha ataca?" ]
                    , p [ class "modal-regra-texto" ]
                        [ text "Em todas as direções em linha reta: "
                        , strong [] [ text "mesma linha, coluna e diagonais" ]
                        , text "."
                        ]
                    , div [ class "modal-legenda" ]
                        [ span [ class "legenda-item" ]
                            [ span [ class "legenda-amostra legenda-amostra--ataque" ] []
                            , text "Atacada (perigo)"
                            ]
                        , span [ class "legenda-item" ]
                            [ span [ class "legenda-amostra legenda-amostra--livre" ] []
                            , text "Casa segura"
                            ]
                        ]
                    ]
                ]
            , div [ class "modal-passos" ]
                [ viewPasso "1" "Clique para jogar" "Toque numa casa para colocar ou mover a rainha daquela linha. Clique de novo para tirar."
                , viewPasso "2" "Acompanhe as cores" "Com Ameaças ligado, os pontinhos mostram onde já há perigo. Se duas se atacarem, ficam vermelhas."
                , viewPasso "3" "Use o Prolog se travar" "Clique em Dica para uma jogada segura, Contar soluções ou Resolver."
                ]
            , div [ class "modal-rodape" ]
                [ span [ class "modal-dica-inicial" ] [ text "Dica: comece pelo 4×4 para pegar o jeito!" ]
                , button [ class "acao-btn acao-btn--primario", onClick FechouAjuda ]
                    [ text "Entendi, vamos jogar!" ]
                ]
            ]
        ]


viewPasso : String -> String -> String -> Html Msg
viewPasso numero titulo descricao =
    div [ class "passo-item" ]
        [ span [ class "passo-num" ] [ text numero ]
        , div [ class "passo-texto" ]
            [ strong [] [ text titulo ]
            , p [] [ text descricao ]
            ]
        ]


viewMiniTabuleiro : Html Msg
viewMiniTabuleiro =
    let
        indices =
            List.range 0 4

        casaMini l c =
            let
                centro =
                    l == 2 && c == 2

                atacada =
                    not centro && (l == 2 || c == 2 || abs (l - 2) == abs (c - 2))
            in
            div
                [ class "mini-casa"
                , classList
                    [ ( "mini-casa--escura", modBy 2 (l + c) == 1 )
                    , ( "mini-casa--rainha", centro )
                    , ( "mini-casa--ataque", atacada )
                    , ( "mini-casa--livre", not centro && not atacada )
                    ]
                ]
                [ if centro then
                    span [ class "rainha-icone mini-rainha", attribute "aria-hidden" "true" ] []

                  else
                    text ""
                ]
    in
    div [ class "mini-tabuleiro", attribute "aria-hidden" "true" ]
        (List.concatMap (\l -> List.map (casaMini l) indices) indices)
