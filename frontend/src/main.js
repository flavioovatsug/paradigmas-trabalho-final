// Ponto de entrada: carrega o CSS e inicia o Elm dentro de <div id="app">.
import "./style.css";
import { Elm } from "./Main.elm";

Elm.Main.init({ node: document.getElementById("app") });
