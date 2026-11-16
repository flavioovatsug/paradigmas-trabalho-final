// Ponto de entrada: carrega o CSS, lê se a ajuda já foi vista e inicia o Elm.
import "./style.css";
import { Elm } from "./Main.elm";

const CHAVE_AJUDA = "n-rainhas-ajuda-vista";

function lerAjudaVista() {
  try {
    return localStorage.getItem(CHAVE_AJUDA) === "1";
  } catch {
    return false;
  }
}

const app = Elm.Main.init({
  node: document.getElementById("app"),
  flags: { mostrarAjuda: !lerAjudaVista() },
});

app.ports?.marcarAjudaVista?.subscribe(() => {
  try {
    localStorage.setItem(CHAVE_AJUDA, "1");
  } catch {
    // Ignora caso o navegador bloqueie localStorage.
  }
});
