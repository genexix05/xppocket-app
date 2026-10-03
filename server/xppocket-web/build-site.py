#!/usr/bin/env python3
"""Generate multilingual static pages for xppocket.app (es / en / pt / fr / de)."""

from __future__ import annotations

from pathlib import Path

from guides_data import GUIDE_ORDER, GUIDE_SEGMENT, GUIDE_UI, GUIDES

ROOT = Path(__file__).resolve().parent / "html"
BASE = "https://xppocket.app"

# prefix "" = Spanish at site root; others under /en/ /pt/ /fr/ /de/
LANGS = ("es", "en", "pt", "fr", "de")
PREFIX = {"es": "", "en": "en", "pt": "pt", "fr": "fr", "de": "de"}
LOCALE = {
    "es": "es_ES",
    "en": "en_US",
    "pt": "pt_BR",
    "fr": "fr_FR",
    "de": "de_DE",
}
HTML_LANG = {
    "es": "es",
    "en": "en",
    "pt": "pt-BR",
    "fr": "fr",
    "de": "de",
}


def path_for(lang: str, page: str) -> str:
    """Public URL path. page: 'home' | 'privacy' | 'terms' | 'guides' | 'guide:<slug>'."""
    pref = PREFIX[lang]
    if page == "home":
        return f"/{pref}/" if pref else "/"
    if page == "privacy":
        return f"/{pref}/privacy" if pref else "/privacy"
    if page == "terms":
        return f"/{pref}/terms" if pref else "/terms"
    seg = GUIDE_SEGMENT[lang]
    if page == "guides":
        return f"/{pref}/{seg}/" if pref else f"/{seg}/"
    if page.startswith("guide:"):
        slug = page.split(":", 1)[1]
        return f"/{pref}/{seg}/{slug}" if pref else f"/{seg}/{slug}"
    raise ValueError(f"unknown page: {page}")


def asset(from_lang: str, name: str) -> str:
    return f"/assets/{name}"


def lang_switcher(current: str, page: str) -> str:
    labels = {"es": "ES", "en": "EN", "pt": "PT", "fr": "FR", "de": "DE"}
    links = []
    for lang in LANGS:
        url = path_for(lang, page)
        cur = ' aria-current="page"' if lang == current else ""
        links.append(f'<a href="{url}"{cur}>{labels[lang]}</a>')
    return '<nav class="lang-switch" aria-label="Language">' + "".join(links) + "</nav>"


def site_footer(lang: str) -> str:
    ui = GUIDE_UI[lang]
    t = HOME[lang]
    return f"""  <footer>
    <div class="footer-inner">
      <p class="footer-brand">XP Pocket</p>
      <div class="footer-links">
        <a href="{path_for(lang, "guides")}">{ui["footer_guides"]}</a>
        <a href="{path_for(lang, "privacy")}">{t["footer_privacy"]}</a>
        <a href="{path_for(lang, "terms")}">{t["footer_terms"]}</a>
        <a href="https://api.xppocket.app/docs">{t["footer_api"]}</a>
        <a href="mailto:support@xppocket.app">{t["footer_support"]}</a>
        <span>© 2026 xppocket.app</span>
      </div>
    </div>
  </footer>"""


def top_nav(lang: str, page: str) -> str:
    ui = GUIDE_UI[lang]
    return f"""    <nav class="nav" aria-label="Primary">
      <a class="nav-mark" href="{path_for(lang, "home")}">
        <img src="/assets/logo.png" width="32" height="32" alt="">
        XP Pocket
      </a>
      <div class="nav-right">
        {lang_switcher(lang, page)}
        <a class="quiet" href="{path_for(lang, "guides")}">{ui["guides_nav"]}</a>
        <a class="quiet" href="{path_for(lang, "privacy")}">{ui["privacy_nav"]}</a>
      </div>
    </nav>"""


HOME = {
    "es": {
        "title": "XP Pocket — Jugar Pokémon Essentials y RPG Maker en iPhone",
        "description": "Juega Pokémon Essentials, Pokémon Añil y otros fan games RPG Maker en iPhone e iPad. Importa tus archivos en XP Pocket. Sin juegos incluidos. No afiliado a Nintendo.",
        "keywords": "Pokémon Essentials iOS, jugar Pokémon Essentials iPhone, Pokémon Añil iPhone, RPG Maker iPhone, mkxp iOS, XP Pocket",
        "og_title": "XP Pocket — Pokémon Essentials y RPG Maker en iPhone",
        "og_description": "Juega Pokémon Essentials, Pokémon Añil y fan games RPG Maker en iOS. Tú importas los archivos.",
        "privacy_nav": "Privacidad",
        "headline": "Pokémon Essentials y RPG Maker en tu iPhone",
        "lede": "Importa tus fan games — Essentials, Añil y más — y júegalos on‑device con controles táctiles a tu medida.",
        "cta_store": "Próximamente en App Store",
        "cta_features": "Ver funciones",
        "cta_note": "iPhone y iPad · iOS 26 o posterior · Sin juegos incluidos",
        "lib_title": "Biblioteca",
        "lib_sub": "Tus juegos importados",
        "feat_kicker": "Por qué XP Pocket",
        "feat_h2": "Hecho para jugar lo tuyo",
        "feat_p": "Una app de reproductor, no un catálogo. Tú aportas los archivos; XP Pocket los ejecuta.",
        "features": [
            ("Importa y listo", "Carpetas y archivos de juegos RPG Maker. Tu biblioteca vive en el dispositivo."),
            ("Controles a medida", "Layouts táctiles personalizables y perfiles por juego. También layouts de la comunidad."),
            ("Motor mkxp‑z", "Compatible con RGSS de RPG Maker XP, VX y VX Ace, optimizado para iOS."),
            ("Cuenta opcional", "Juega sin registrarte. Sign in with Apple desbloquea cloud save y extras Pro."),
        ],
        "seo_kicker": "Fan games en iOS",
        "seo_h2": "Jugar Pokémon Essentials en iPhone",
        "seo_intro": "Si buscas cómo jugar Pokémon Essentials o Pokémon Añil en iOS, XP Pocket es el reproductor: tú importas el juego.",
        "seo_blocks": [
            (
                "Pokémon Essentials en iPhone e iPad.",
                "Muchos fan games están construidos sobre Pokémon Essentials y RPG Maker XP. Con XP Pocket puedes abrir esos proyectos en iOS: importa la carpeta o el archivo del juego que ya tengas y juega con controles táctiles.",
            ),
            (
                "Pokémon Añil en iPhone.",
                "Si tienes Pokémon Añil (u otros títulos en español basados en Essentials) en tu dispositivo, puedes cargarlos en XP Pocket. La app no descarga ni redistribuye Añil: solo ejecuta lo que tú aportas.",
            ),
            (
                "",
                "También encajan otros fan games RPG Maker / mkxp que ya uses en ordenador, siempre que cuentes con los archivos y el derecho a jugarlos.",
            ),
        ],
        "faqs": [
            (
                "¿Puedo jugar Pokémon Essentials en iPhone?",
                "Sí, importando en XP Pocket un proyecto compatible (Essentials / RPG Maker XP) del que tengas derechos. La app no incluye el juego.",
            ),
            (
                "¿Puedo jugar Pokémon Añil en iPhone o iPad?",
                "Sí, si dispones de tus propios archivos de Añil y los importas. XP Pocket no ofrece descarga del juego.",
            ),
            (
                "¿Hay que pagar o crear cuenta?",
                "Puedes jugar sin cuenta. Sign in with Apple es opcional (cloud save y extras Pro).",
            ),
        ],
        "disclaimer": "Pokémon y demás marcas relacionadas son propiedad de Nintendo, Game Freak y The Pokémon Company. XP Pocket no está afiliado ni respaldado por ellos. No incluimos ni distribuimos juegos, ROMs ni assets con copyright de terceros.",
        "compat_kicker": "Compatibilidad",
        "compat_h2": "XP, VX, VX Ace y Essentials",
        "compat_p": "Motor mkxp‑z para RPG Maker clásico y proyectos Essentials que importes tú.",
        "legal_note": "XP Pocket no incluye juegos. Solo importa contenido del que tengas derechos. Software libre bajo GPL — el código fuente se publica junto a cada versión.",
        "footer_privacy": "Privacidad",
        "footer_terms": "Términos",
        "footer_api": "API",
        "footer_support": "Soporte",
        "schema_desc": "Reproduce en iPhone e iPad juegos RPG Maker y proyectos Pokémon Essentials (p. ej. Pokémon Añil) que el usuario importa. No incluye juegos. No afiliado a Nintendo.",
        "faq_schema": [
            (
                "¿Puedo jugar Pokémon Essentials en iPhone?",
                "Sí. XP Pocket ejecuta juegos RPG Maker y proyectos Essentials que tú importas. No incluye juegos.",
            ),
            (
                "¿Puedo jugar Pokémon Añil en iPhone o iPad?",
                "Si tienes una copia de Pokémon Añil, puedes importarla en XP Pocket. La app no distribuye el juego.",
            ),
            (
                "¿XP Pocket está afiliado a Nintendo o Pokémon?",
                "No. Es un proyecto independiente. Solo ejecuta archivos que el usuario importa.",
            ),
        ],
    },
    "en": {
        "title": "XP Pocket — Play Pokémon Essentials & RPG Maker on iPhone",
        "description": "Play Pokémon Essentials, Pokémon Añil, and other RPG Maker fan games on iPhone and iPad. Import your own files. No games included. Not affiliated with Nintendo.",
        "keywords": "Pokémon Essentials iOS, play Pokémon Essentials iPhone, Pokémon Añil iPhone, RPG Maker iPhone, mkxp iOS, XP Pocket",
        "og_title": "XP Pocket — Pokémon Essentials & RPG Maker on iPhone",
        "og_description": "Play Pokémon Essentials and RPG Maker fan games on iOS. You import the files. No games included.",
        "privacy_nav": "Privacy",
        "headline": "Pokémon Essentials & RPG Maker on your iPhone",
        "lede": "Import your fan games — Essentials, Añil, and more — and play on‑device with custom touch controls.",
        "cta_store": "Coming soon to the App Store",
        "cta_features": "See features",
        "cta_note": "iPhone and iPad · iOS 26 or later · No games included",
        "lib_title": "Library",
        "lib_sub": "Your imported games",
        "feat_kicker": "Why XP Pocket",
        "feat_h2": "Built to play your games",
        "feat_p": "A player app, not a catalog. You bring the files; XP Pocket runs them.",
        "features": [
            ("Import and play", "RPG Maker folders and archives. Your library stays on device."),
            ("Custom controls", "Per-game touch layouts, plus community layout packs."),
            ("mkxp‑z engine", "RGSS for RPG Maker XP, VX, and VX Ace, tuned for iOS."),
            ("Optional account", "Play without signing in. Sign in with Apple unlocks cloud save and Pro extras."),
        ],
        "seo_kicker": "Fan games on iOS",
        "seo_h2": "Play Pokémon Essentials on iPhone",
        "seo_intro": "Looking for Pokémon Essentials or Pokémon Añil on iOS? XP Pocket is the player — you import the game.",
        "seo_blocks": [
            (
                "Pokémon Essentials on iPhone and iPad.",
                "Many fan games are built on Pokémon Essentials and RPG Maker XP. Import the game folder or archive you already have and play with touch controls.",
            ),
            (
                "Pokémon Añil on iPhone.",
                "If you have Pokémon Añil (or other Essentials-based titles) on your device, load them in XP Pocket. We do not download or redistribute Añil — we only run what you provide.",
            ),
            (
                "",
                "Other RPG Maker / mkxp fan games you already play on PC work the same way, as long as you have the files and the rights to use them.",
            ),
        ],
        "faqs": [
            (
                "Can I play Pokémon Essentials on iPhone?",
                "Yes — import a compatible Essentials / RPG Maker XP project you have rights to. The app does not include the game.",
            ),
            (
                "Can I play Pokémon Añil on iPhone or iPad?",
                "Yes, if you have your own Añil files and import them. XP Pocket does not offer a download.",
            ),
            (
                "Do I need to pay or create an account?",
                "You can play without an account. Sign in with Apple is optional (cloud save and Pro extras).",
            ),
        ],
        "disclaimer": "Pokémon and related marks are owned by Nintendo, Game Freak, and The Pokémon Company. XP Pocket is not affiliated with or endorsed by them. We do not include or distribute games, ROMs, or third-party copyrighted assets.",
        "compat_kicker": "Compatibility",
        "compat_h2": "XP, VX, VX Ace & Essentials",
        "compat_p": "mkxp‑z engine for classic RPG Maker and Essentials projects you import.",
        "legal_note": "XP Pocket includes no games. Import only content you have rights to use. Free software under the GPL — source is published with each release.",
        "footer_privacy": "Privacy",
        "footer_terms": "Terms",
        "footer_api": "API",
        "footer_support": "Support",
        "schema_desc": "Play RPG Maker and Pokémon Essentials projects (e.g. Pokémon Añil) on iPhone and iPad by importing your own files. No games included. Not affiliated with Nintendo.",
        "faq_schema": [
            (
                "Can I play Pokémon Essentials on iPhone?",
                "Yes. XP Pocket runs RPG Maker and Essentials projects you import. No games are bundled.",
            ),
            (
                "Can I play Pokémon Añil on iPhone or iPad?",
                "If you have Pokémon Añil, you can import it into XP Pocket. The app does not distribute the game.",
            ),
            (
                "Is XP Pocket affiliated with Nintendo or Pokémon?",
                "No. It is an independent project. It only runs files the user imports.",
            ),
        ],
    },
    "pt": {
        "title": "XP Pocket — Jogar Pokémon Essentials e RPG Maker no iPhone",
        "description": "Jogue Pokémon Essentials, Pokémon Añil e outros fan games de RPG Maker no iPhone e iPad. Importe os seus ficheiros. Sem jogos incluídos. Não afiliado à Nintendo.",
        "keywords": "Pokémon Essentials iOS, jogar Pokémon Essentials iPhone, Pokémon Añil iPhone, RPG Maker iPhone, mkxp iOS, XP Pocket",
        "og_title": "XP Pocket — Pokémon Essentials e RPG Maker no iPhone",
        "og_description": "Jogue Pokémon Essentials e fan games RPG Maker no iOS. Você importa os ficheiros. Sem jogos incluídos.",
        "privacy_nav": "Privacidade",
        "headline": "Pokémon Essentials e RPG Maker no seu iPhone",
        "lede": "Importe os seus fan games — Essentials, Añil e mais — e jogue no dispositivo com controlos táteis à sua medida.",
        "cta_store": "Em breve na App Store",
        "cta_features": "Ver funções",
        "cta_note": "iPhone e iPad · iOS 26 ou posterior · Sem jogos incluídos",
        "lib_title": "Biblioteca",
        "lib_sub": "Os seus jogos importados",
        "feat_kicker": "Porquê o XP Pocket",
        "feat_h2": "Feito para jogar o que é seu",
        "feat_p": "Uma app de leitor, não um catálogo. Você traz os ficheiros; o XP Pocket executa-os.",
        "features": [
            ("Importe e jogue", "Pastas e arquivos RPG Maker. A biblioteca fica no dispositivo."),
            ("Controlos à medida", "Layouts táteis por jogo e packs da comunidade."),
            ("Motor mkxp‑z", "RGSS para RPG Maker XP, VX e VX Ace, otimizado para iOS."),
            ("Conta opcional", "Jogue sem registo. Sign in with Apple desbloqueia cloud save e extras Pro."),
        ],
        "seo_kicker": "Fan games no iOS",
        "seo_h2": "Jogar Pokémon Essentials no iPhone",
        "seo_intro": "Procura jogar Pokémon Essentials ou Pokémon Añil no iOS? O XP Pocket é o leitor: você importa o jogo.",
        "seo_blocks": [
            (
                "Pokémon Essentials no iPhone e iPad.",
                "Muitos fan games usam Pokémon Essentials e RPG Maker XP. Importe a pasta ou o arquivo que já tem e jogue com controlos táteis.",
            ),
            (
                "Pokémon Añil no iPhone.",
                "Se tiver Pokémon Añil (ou outros títulos baseados em Essentials) no dispositivo, carregue-os no XP Pocket. A app não descarrega nem redistribui Añil.",
            ),
            (
                "",
                "Outros fan games RPG Maker / mkxp que já jogue no PC funcionam da mesma forma, desde que tenha os ficheiros e o direito de os usar.",
            ),
        ],
        "faqs": [
            (
                "Posso jogar Pokémon Essentials no iPhone?",
                "Sim — importe um projeto Essentials / RPG Maker XP de que tenha direitos. A app não inclui o jogo.",
            ),
            (
                "Posso jogar Pokémon Añil no iPhone ou iPad?",
                "Sim, se tiver os seus ficheiros de Añil e os importar. O XP Pocket não oferece download.",
            ),
            (
                "É preciso pagar ou criar conta?",
                "Pode jogar sem conta. Sign in with Apple é opcional (cloud save e extras Pro).",
            ),
        ],
        "disclaimer": "Pokémon e marcas relacionadas são propriedade da Nintendo, Game Freak e The Pokémon Company. O XP Pocket não é afiliado nem endossado por elas. Não incluímos nem distribuímos jogos, ROMs ou assets com copyright de terceiros.",
        "compat_kicker": "Compatibilidade",
        "compat_h2": "XP, VX, VX Ace e Essentials",
        "compat_p": "Motor mkxp‑z para RPG Maker clássico e projetos Essentials que você importa.",
        "legal_note": "O XP Pocket não inclui jogos. Importe apenas conteúdo de que tenha direitos. Software livre sob GPL — o código-fonte é publicado com cada versão.",
        "footer_privacy": "Privacidade",
        "footer_terms": "Termos",
        "footer_api": "API",
        "footer_support": "Suporte",
        "schema_desc": "Reproduza no iPhone e iPad jogos RPG Maker e projetos Pokémon Essentials (ex.: Pokémon Añil) que o utilizador importa. Sem jogos incluídos. Não afiliado à Nintendo.",
        "faq_schema": [
            (
                "Posso jogar Pokémon Essentials no iPhone?",
                "Sim. O XP Pocket executa projetos RPG Maker e Essentials que você importa. Não inclui jogos.",
            ),
            (
                "Posso jogar Pokémon Añil no iPhone ou iPad?",
                "Se tiver Pokémon Añil, pode importá-lo no XP Pocket. A app não distribui o jogo.",
            ),
            (
                "O XP Pocket é afiliado à Nintendo ou Pokémon?",
                "Não. É um projeto independente. Só executa ficheiros que o utilizador importa.",
            ),
        ],
    },
    "fr": {
        "title": "XP Pocket — Jouer à Pokémon Essentials et RPG Maker sur iPhone",
        "description": "Jouez à Pokémon Essentials, Pokémon Añil et d'autres fan games RPG Maker sur iPhone et iPad. Importez vos fichiers. Aucun jeu inclus. Non affilié à Nintendo.",
        "keywords": "Pokémon Essentials iOS, jouer Pokémon Essentials iPhone, Pokémon Añil iPhone, RPG Maker iPhone, mkxp iOS, XP Pocket",
        "og_title": "XP Pocket — Pokémon Essentials et RPG Maker sur iPhone",
        "og_description": "Jouez à Pokémon Essentials et aux fan games RPG Maker sur iOS. Vous importez les fichiers. Aucun jeu inclus.",
        "privacy_nav": "Confidentialité",
        "headline": "Pokémon Essentials et RPG Maker sur votre iPhone",
        "lede": "Importez vos fan games — Essentials, Añil et plus — et jouez sur l'appareil avec des contrôles tactiles sur mesure.",
        "cta_store": "Bientôt sur l'App Store",
        "cta_features": "Voir les fonctions",
        "cta_note": "iPhone et iPad · iOS 26 ou plus · Aucun jeu inclus",
        "lib_title": "Bibliothèque",
        "lib_sub": "Vos jeux importés",
        "feat_kicker": "Pourquoi XP Pocket",
        "feat_h2": "Conçu pour jouer à vos jeux",
        "feat_p": "Une app lecteur, pas un catalogue. Vous apportez les fichiers ; XP Pocket les exécute.",
        "features": [
            ("Importez et jouez", "Dossiers et archives RPG Maker. Votre bibliothèque reste sur l'appareil."),
            ("Contrôles sur mesure", "Layouts tactiles par jeu et packs de la communauté."),
            ("Moteur mkxp‑z", "RGSS pour RPG Maker XP, VX et VX Ace, optimisé pour iOS."),
            ("Compte optionnel", "Jouez sans compte. Sign in with Apple débloque le cloud save et les extras Pro."),
        ],
        "seo_kicker": "Fan games sur iOS",
        "seo_h2": "Jouer à Pokémon Essentials sur iPhone",
        "seo_intro": "Vous cherchez à jouer à Pokémon Essentials ou Pokémon Añil sur iOS ? XP Pocket est le lecteur : vous importez le jeu.",
        "seo_blocks": [
            (
                "Pokémon Essentials sur iPhone et iPad.",
                "De nombreux fan games sont construits sur Pokémon Essentials et RPG Maker XP. Importez le dossier ou l'archive que vous avez déjà et jouez avec des contrôles tactiles.",
            ),
            (
                "Pokémon Añil sur iPhone.",
                "Si vous avez Pokémon Añil (ou d'autres titres basés sur Essentials) sur votre appareil, chargez-les dans XP Pocket. L'app ne télécharge ni ne redistribue Añil.",
            ),
            (
                "",
                "D'autres fan games RPG Maker / mkxp que vous jouez déjà sur PC fonctionnent de la même façon, tant que vous avez les fichiers et le droit de les utiliser.",
            ),
        ],
        "faqs": [
            (
                "Puis-je jouer à Pokémon Essentials sur iPhone ?",
                "Oui — importez un projet Essentials / RPG Maker XP dont vous avez les droits. L'app n'inclut pas le jeu.",
            ),
            (
                "Puis-je jouer à Pokémon Añil sur iPhone ou iPad ?",
                "Oui, si vous avez vos propres fichiers Añil et que vous les importez. XP Pocket ne propose pas de téléchargement.",
            ),
            (
                "Faut-il payer ou créer un compte ?",
                "Vous pouvez jouer sans compte. Sign in with Apple est optionnel (cloud save et extras Pro).",
            ),
        ],
        "disclaimer": "Pokémon et les marques associées appartiennent à Nintendo, Game Freak et The Pokémon Company. XP Pocket n'est ni affilié ni approuvé par eux. Nous n'incluons ni ne distribuons de jeux, ROMs ou assets protégés par le droit d'auteur de tiers.",
        "compat_kicker": "Compatibilité",
        "compat_h2": "XP, VX, VX Ace et Essentials",
        "compat_p": "Moteur mkxp‑z pour RPG Maker classique et projets Essentials que vous importez.",
        "legal_note": "XP Pocket n'inclut aucun jeu. N'importez que du contenu dont vous avez les droits. Logiciel libre sous GPL — le code source est publié avec chaque version.",
        "footer_privacy": "Confidentialité",
        "footer_terms": "Conditions",
        "footer_api": "API",
        "footer_support": "Support",
        "schema_desc": "Jouez sur iPhone et iPad à des jeux RPG Maker et projets Pokémon Essentials (ex. Pokémon Añil) que l'utilisateur importe. Aucun jeu inclus. Non affilié à Nintendo.",
        "faq_schema": [
            (
                "Puis-je jouer à Pokémon Essentials sur iPhone ?",
                "Oui. XP Pocket exécute les projets RPG Maker et Essentials que vous importez. Aucun jeu n'est fourni.",
            ),
            (
                "Puis-je jouer à Pokémon Añil sur iPhone ou iPad ?",
                "Si vous avez Pokémon Añil, vous pouvez l'importer dans XP Pocket. L'app ne distribue pas le jeu.",
            ),
            (
                "XP Pocket est-il affilié à Nintendo ou Pokémon ?",
                "Non. C'est un projet indépendant. Il n'exécute que les fichiers importés par l'utilisateur.",
            ),
        ],
    },
    "de": {
        "title": "XP Pocket — Pokémon Essentials und RPG Maker auf dem iPhone spielen",
        "description": "Spiele Pokémon Essentials, Pokémon Añil und andere RPG-Maker-Fan-Games auf iPhone und iPad. Importiere deine Dateien. Keine Spiele enthalten. Nicht mit Nintendo verbunden.",
        "keywords": "Pokémon Essentials iOS, Pokémon Essentials iPhone spielen, Pokémon Añil iPhone, RPG Maker iPhone, mkxp iOS, XP Pocket",
        "og_title": "XP Pocket — Pokémon Essentials und RPG Maker auf dem iPhone",
        "og_description": "Spiele Pokémon Essentials und RPG-Maker-Fan-Games auf iOS. Du importierst die Dateien. Keine Spiele enthalten.",
        "privacy_nav": "Datenschutz",
        "headline": "Pokémon Essentials und RPG Maker auf deinem iPhone",
        "lede": "Importiere deine Fan-Games — Essentials, Añil und mehr — und spiele sie on‑device mit individuellen Touch-Steuerungen.",
        "cta_store": "Bald im App Store",
        "cta_features": "Funktionen ansehen",
        "cta_note": "iPhone und iPad · iOS 26 oder neuer · Keine Spiele enthalten",
        "lib_title": "Bibliothek",
        "lib_sub": "Deine importierten Spiele",
        "feat_kicker": "Warum XP Pocket",
        "feat_h2": "Gebaut, um deine Spiele zu spielen",
        "feat_p": "Eine Player-App, kein Katalog. Du bringst die Dateien mit; XP Pocket führt sie aus.",
        "features": [
            ("Importieren und spielen", "RPG-Maker-Ordner und Archive. Deine Bibliothek bleibt auf dem Gerät."),
            ("Individuelle Steuerung", "Touch-Layouts pro Spiel sowie Community-Packs."),
            ("mkxp‑z-Engine", "RGSS für RPG Maker XP, VX und VX Ace, optimiert für iOS."),
            ("Optionales Konto", "Spielen ohne Anmeldung. Sign in with Apple schaltet Cloud-Save und Pro-Extras frei."),
        ],
        "seo_kicker": "Fan-Games auf iOS",
        "seo_h2": "Pokémon Essentials auf dem iPhone spielen",
        "seo_intro": "Du suchst Pokémon Essentials oder Pokémon Añil auf iOS? XP Pocket ist der Player — du importierst das Spiel.",
        "seo_blocks": [
            (
                "Pokémon Essentials auf iPhone und iPad.",
                "Viele Fan-Games basieren auf Pokémon Essentials und RPG Maker XP. Importiere den Ordner oder das Archiv, das du bereits hast, und spiele mit Touch-Steuerung.",
            ),
            (
                "Pokémon Añil auf dem iPhone.",
                "Wenn du Pokémon Añil (oder andere Essentials-Titel) auf dem Gerät hast, lade sie in XP Pocket. Die App lädt Añil nicht herunter und verteilt es nicht.",
            ),
            (
                "",
                "Andere RPG-Maker-/mkxp-Fan-Games, die du schon am PC spielst, funktionieren genauso — sofern du die Dateien und die Nutzungsrechte hast.",
            ),
        ],
        "faqs": [
            (
                "Kann ich Pokémon Essentials auf dem iPhone spielen?",
                "Ja — importiere ein kompatibles Essentials-/RPG-Maker-XP-Projekt, an dem du Rechte hast. Die App enthält das Spiel nicht.",
            ),
            (
                "Kann ich Pokémon Añil auf iPhone oder iPad spielen?",
                "Ja, wenn du eigene Añil-Dateien hast und sie importierst. XP Pocket bietet keinen Download an.",
            ),
            (
                "Muss ich bezahlen oder ein Konto erstellen?",
                "Du kannst ohne Konto spielen. Sign in with Apple ist optional (Cloud-Save und Pro-Extras).",
            ),
        ],
        "disclaimer": "Pokémon und verwandte Marken gehören Nintendo, Game Freak und The Pokémon Company. XP Pocket ist nicht mit ihnen verbunden und wird nicht von ihnen unterstützt. Wir enthalten und verteilen keine Spiele, ROMs oder urheberrechtlich geschützte Assets Dritter.",
        "compat_kicker": "Kompatibilität",
        "compat_h2": "XP, VX, VX Ace und Essentials",
        "compat_p": "mkxp‑z-Engine für klassisches RPG Maker und Essentials-Projekte, die du importierst.",
        "legal_note": "XP Pocket enthält keine Spiele. Importiere nur Inhalte, an denen du Rechte hast. Freie Software unter der GPL — der Quellcode wird mit jeder Version veröffentlicht.",
        "footer_privacy": "Datenschutz",
        "footer_terms": "Nutzungsbedingungen",
        "footer_api": "API",
        "footer_support": "Support",
        "schema_desc": "Spiele auf iPhone und iPad RPG-Maker- und Pokémon-Essentials-Projekte (z. B. Pokémon Añil), die der Nutzer importiert. Keine Spiele enthalten. Nicht mit Nintendo verbunden.",
        "faq_schema": [
            (
                "Kann ich Pokémon Essentials auf dem iPhone spielen?",
                "Ja. XP Pocket führt RPG-Maker- und Essentials-Projekte aus, die du importierst. Es sind keine Spiele enthalten.",
            ),
            (
                "Kann ich Pokémon Añil auf iPhone oder iPad spielen?",
                "Wenn du Pokémon Añil hast, kannst du es in XP Pocket importieren. Die App verteilt das Spiel nicht.",
            ),
            (
                "Ist XP Pocket mit Nintendo oder Pokémon verbunden?",
                "Nein. Es ist ein unabhängiges Projekt. Es führt nur Dateien aus, die der Nutzer importiert.",
            ),
        ],
    },
}

PRIVACY = {
    "es": {
        "title": "Privacidad — XP Pocket",
        "description": "Política de privacidad de XP Pocket para iOS.",
        "back": "← XP Pocket",
        "h1": "Política de privacidad",
        "updated": "Última actualización: 24 de agosto de 2026",
        "sections": [
            ("Responsable", "<p>XP Pocket (<a href=\"https://xppocket.app\">xppocket.app</a>). Contacto: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>"),
            ("Resumen", "<p>Puedes usar XP Pocket sin cuenta. Si inicias sesión con Apple o usas guardado en la nube (Pro), algunos datos se envían a nuestros servidores para prestar ese servicio. No vendemos datos personales ni usamos publicidad en la app.</p>"),
            (
                "Datos en el dispositivo",
                "<ul><li>Preferencias (ajustes, layouts táctiles).</li><li>Juegos y partidas que importas o generas al jugar.</li><li>Metadatos de archivos usados por iOS (p. ej. fechas).</li><li>Logs de diagnóstico opcionales, solo locales, si los activas en Ajustes.</li></ul>",
            ),
            (
                "Cuenta opcional (Sign in with Apple)",
                "<p>Si eliges iniciar sesión:</p><ul><li>Recibimos un identificador de cuenta de Apple.</li><li>Podemos recibir un email (el real o el oculto de Apple, según tu elección).</li><li>Usamos esa información para autenticarte y asociar funciones de cuenta (p. ej. Pro, cloud save).</li></ul>",
            ),
            (
                "Cloud save (Pro, opcional)",
                "<p>Si subes o descargas partidas a la nube, el archivo de guardado y metadatos del juego (título, tamaño, fecha) se almacenan en nuestros servidores vinculados a tu cuenta. Tú controlas cuándo subir o borrar. No usamos tus partidas para publicidad ni las compartimos con terceros.</p>",
            ),
            (
                "Layouts comunitarios",
                "<p>La app puede conectarse a <a href=\"https://api.xppocket.app\">api.xppocket.app</a> para listar o descargar layouts. Esas peticiones no exigen cuenta. Si publicas un layout (función de administración), se guarda el contenido que envías.</p>",
            ),
            (
                "Qué no hacemos",
                "<ul><li>No hay SDK de analítica de terceros ni publicidad en la versión actual.</li><li>No hacemos seguimiento (tracking) entre apps.</li><li>No vendemos datos personales.</li></ul>",
            ),
            (
                "Terceros",
                "<p>XP Pocket incluye software open source (mkxp-z, SDL, etc.). Apple puede recibir informes de fallos anónimos si los activas en iOS. Sign in with Apple lo opera Apple; su política aplica al flujo de autenticación.</p>",
            ),
            (
                "Base legal y conservación (UE)",
                "<p>Tratamos datos de cuenta y cloud save para ejecutar el servicio que solicitas. Conservamos la cuenta y los saves mientras mantengas la cuenta o hasta que solicites borrado. Puedes pedir acceso, rectificación o eliminación en <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>",
            ),
            ("Menores", "<p>No recopilamos datos de menores de forma intencionada. Clasificación y uso conforme a App Store.</p>"),
            ("Cambios", "<p>Publicaremos cambios en esta página con una nueva fecha.</p>"),
        ],
    },
    "en": {
        "title": "Privacy — XP Pocket",
        "description": "XP Pocket privacy policy for iOS.",
        "back": "← XP Pocket",
        "h1": "Privacy Policy",
        "updated": "Last updated: 24 August 2026",
        "sections": [
            ("Controller", "<p>XP Pocket (<a href=\"https://xppocket.app\">xppocket.app</a>). Contact: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>"),
            ("Summary", "<p>You can use XP Pocket without an account. If you Sign in with Apple or use cloud save (Pro), some data is sent to our servers to provide that service. We do not sell personal data or show ads in the app.</p>"),
            (
                "On-device data",
                "<ul><li>Preferences (settings, touch layouts).</li><li>Games and save files you import or create while playing.</li><li>File metadata used by iOS (e.g. timestamps).</li><li>Optional local diagnostic logs if you enable them in Settings.</li></ul>",
            ),
            (
                "Optional account (Sign in with Apple)",
                "<p>If you choose to sign in:</p><ul><li>We receive an Apple account identifier.</li><li>We may receive an email address (real or Apple’s Hide My Email), depending on your choice.</li><li>We use this to authenticate you and attach account features (e.g. Pro, cloud save).</li></ul>",
            ),
            (
                "Cloud save (Pro, optional)",
                "<p>If you upload or download saves, the save pack and game metadata (title, size, date) are stored on our servers linked to your account. You control when to upload or delete. We do not use your saves for advertising or share them with third parties.</p>",
            ),
            (
                "Community layouts",
                "<p>The app may contact <a href=\"https://api.xppocket.app\">api.xppocket.app</a> to list or download layouts. No account is required for browsing. Admin publishing stores the content you submit.</p>",
            ),
            (
                "What we do not do",
                "<ul><li>No third-party analytics or advertising SDKs in the current version.</li><li>No cross-app tracking.</li><li>We do not sell personal data.</li></ul>",
            ),
            (
                "Third parties",
                "<p>XP Pocket includes open-source libraries (mkxp-z, SDL, and others). Apple may receive anonymous crash reports if you enable them on iOS. Sign in with Apple is operated by Apple; their policy applies to that auth flow.</p>",
            ),
            (
                "Retention & rights (EU)",
                "<p>We process account and cloud-save data to provide the service you request. We keep account and saves while your account exists or until you ask for deletion. Contact <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a> for access, correction, or deletion.</p>",
            ),
            ("Children", "<p>We do not knowingly collect children’s data. Use follows App Store age ratings.</p>"),
            ("Changes", "<p>We will post updates on this page with a new date.</p>"),
        ],
    },
    "pt": {
        "title": "Privacidade — XP Pocket",
        "description": "Política de privacidade do XP Pocket para iOS.",
        "back": "← XP Pocket",
        "h1": "Política de privacidade",
        "updated": "Última atualização: 24 de agosto de 2026",
        "sections": [
            ("Responsável", "<p>XP Pocket (<a href=\"https://xppocket.app\">xppocket.app</a>). Contacto: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>"),
            ("Resumo", "<p>Pode usar o XP Pocket sem conta. Se iniciar sessão com a Apple ou usar cloud save (Pro), alguns dados são enviados para os nossos servidores. Não vendemos dados pessoais nem usamos publicidade na app.</p>"),
            (
                "Dados no dispositivo",
                "<ul><li>Preferências (definições, layouts táteis).</li><li>Jogos e saves que importa ou cria ao jogar.</li><li>Metadados de ficheiros usados pelo iOS.</li><li>Logs de diagnóstico opcionais, só locais, se os ativar.</li></ul>",
            ),
            (
                "Conta opcional (Sign in with Apple)",
                "<p>Se escolher iniciar sessão:</p><ul><li>Recebemos um identificador de conta Apple.</li><li>Podemos receber um email (real ou Hide My Email).</li><li>Usamos isso para autenticá-lo e associar funções de conta (Pro, cloud save).</li></ul>",
            ),
            (
                "Cloud save (Pro, opcional)",
                "<p>Se enviar ou descarregar saves, o pacote e metadados do jogo ficam nos nossos servidores ligados à sua conta. Você controla quando enviar ou apagar. Não usamos os saves para publicidade nem os partilhamos com terceiros.</p>",
            ),
            (
                "Layouts da comunidade",
                "<p>A app pode contactar <a href=\"https://api.xppocket.app\">api.xppocket.app</a> para listar ou descarregar layouts. Não é necessária conta para navegar.</p>",
            ),
            (
                "O que não fazemos",
                "<ul><li>Sem SDK de analytics ou publicidade na versão atual.</li><li>Sem tracking entre apps.</li><li>Não vendemos dados pessoais.</li></ul>",
            ),
            (
                "Terceiros",
                "<p>O XP Pocket inclui software open source (mkxp-z, SDL, etc.). A Apple pode receber relatórios de crash anónimos se os ativar. O Sign in with Apple é operado pela Apple.</p>",
            ),
            (
                "Conservação e direitos (UE)",
                "<p>Tratamos dados de conta e cloud save para prestar o serviço. Conservamos enquanto a conta existir ou até pedir eliminação. Contacte <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>",
            ),
            ("Menores", "<p>Não recolhemos dados de menores de forma intencional. Uso conforme a App Store.</p>"),
            ("Alterações", "<p>Publicaremos alterações nesta página com uma nova data.</p>"),
        ],
    },
    "fr": {
        "title": "Confidentialité — XP Pocket",
        "description": "Politique de confidentialité de XP Pocket pour iOS.",
        "back": "← XP Pocket",
        "h1": "Politique de confidentialité",
        "updated": "Dernière mise à jour : 24 août 2026",
        "sections": [
            ("Responsable", "<p>XP Pocket (<a href=\"https://xppocket.app\">xppocket.app</a>). Contact : <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>"),
            ("Résumé", "<p>Vous pouvez utiliser XP Pocket sans compte. Si vous vous connectez avec Apple ou utilisez la sauvegarde cloud (Pro), certaines données sont envoyées à nos serveurs pour fournir ce service. Nous ne vendons pas de données personnelles et n'affichons pas de publicité dans l'app.</p>"),
            (
                "Données sur l'appareil",
                "<ul><li>Préférences (réglages, layouts tactiles).</li><li>Jeux et sauvegardes que vous importez ou créez en jouant.</li><li>Métadonnées de fichiers utilisées par iOS.</li><li>Journaux de diagnostic optionnels, uniquement locaux, si vous les activez.</li></ul>",
            ),
            (
                "Compte optionnel (Sign in with Apple)",
                "<p>Si vous choisissez de vous connecter :</p><ul><li>Nous recevons un identifiant de compte Apple.</li><li>Nous pouvons recevoir une adresse e-mail (réelle ou Masquer mon e-mail), selon votre choix.</li><li>Nous l'utilisons pour vous authentifier et associer les fonctions de compte (Pro, cloud save).</li></ul>",
            ),
            (
                "Cloud save (Pro, optionnel)",
                "<p>Si vous téléversez ou téléchargez des sauvegardes, le pack et les métadonnées du jeu sont stockés sur nos serveurs liés à votre compte. Vous contrôlez quand envoyer ou supprimer. Nous n'utilisons pas vos sauvegardes pour la publicité et ne les partageons pas avec des tiers.</p>",
            ),
            (
                "Layouts communautaires",
                "<p>L'app peut contacter <a href=\"https://api.xppocket.app\">api.xppocket.app</a> pour lister ou télécharger des layouts. Aucun compte n'est requis pour parcourir.</p>",
            ),
            (
                "Ce que nous ne faisons pas",
                "<ul><li>Pas de SDK d'analytics ou de publicité dans la version actuelle.</li><li>Pas de suivi inter-apps.</li><li>Nous ne vendons pas de données personnelles.</li></ul>",
            ),
            (
                "Tiers",
                "<p>XP Pocket inclut des logiciels open source (mkxp-z, SDL, etc.). Apple peut recevoir des rapports de plantage anonymes si vous les activez. Sign in with Apple est géré par Apple.</p>",
            ),
            (
                "Conservation et droits (UE)",
                "<p>Nous traitons les données de compte et de cloud save pour fournir le service demandé. Nous les conservons tant que le compte existe ou jusqu'à une demande de suppression. Contactez <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>",
            ),
            ("Mineurs", "<p>Nous ne collectons pas volontairement de données de mineurs. L'usage suit les classifications App Store.</p>"),
            ("Modifications", "<p>Nous publierons les changements sur cette page avec une nouvelle date.</p>"),
        ],
    },
    "de": {
        "title": "Datenschutz — XP Pocket",
        "description": "Datenschutzerklärung von XP Pocket für iOS.",
        "back": "← XP Pocket",
        "h1": "Datenschutzerklärung",
        "updated": "Zuletzt aktualisiert: 24. August 2026",
        "sections": [
            ("Verantwortlicher", "<p>XP Pocket (<a href=\"https://xppocket.app\">xppocket.app</a>). Kontakt: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>"),
            ("Kurzfassung", "<p>Du kannst XP Pocket ohne Konto nutzen. Wenn du dich mit Apple anmeldest oder Cloud-Save (Pro) verwendest, werden einige Daten an unsere Server gesendet, um diesen Dienst zu erbringen. Wir verkaufen keine personenbezogenen Daten und zeigen keine Werbung in der App.</p>"),
            (
                "Daten auf dem Gerät",
                "<ul><li>Einstellungen (Optionen, Touch-Layouts).</li><li>Spiele und Speicherstände, die du importierst oder beim Spielen erzeugst.</li><li>Dateimetadaten von iOS.</li><li>Optionale lokale Diagnoselogs, wenn du sie aktivierst.</li></ul>",
            ),
            (
                "Optionales Konto (Sign in with Apple)",
                "<p>Wenn du dich anmeldest:</p><ul><li>Wir erhalten eine Apple-Konto-ID.</li><li>Wir können eine E-Mail-Adresse erhalten (echt oder Hide My Email), je nach deiner Wahl.</li><li>Wir nutzen das zur Authentifizierung und für Kontofunktionen (Pro, Cloud-Save).</li></ul>",
            ),
            (
                "Cloud-Save (Pro, optional)",
                "<p>Wenn du Speicherstände hoch- oder herunterlädst, werden das Paket und Spielmetadaten auf unseren Servern mit deinem Konto verknüpft gespeichert. Du entscheidest, wann du hochlädst oder löschst. Wir nutzen deine Saves nicht für Werbung und geben sie nicht an Dritte weiter.</p>",
            ),
            (
                "Community-Layouts",
                "<p>Die App kann <a href=\"https://api.xppocket.app\">api.xppocket.app</a> kontaktieren, um Layouts aufzulisten oder herunterzuladen. Zum Durchsuchen ist kein Konto nötig.</p>",
            ),
            (
                "Was wir nicht tun",
                "<ul><li>Keine Analytics- oder Werbe-SDKs in der aktuellen Version.</li><li>Kein App-übergreifendes Tracking.</li><li>Wir verkaufen keine personenbezogenen Daten.</li></ul>",
            ),
            (
                "Dritte",
                "<p>XP Pocket enthält Open-Source-Software (mkxp-z, SDL usw.). Apple kann anonyme Absturzberichte erhalten, wenn du sie aktivierst. Sign in with Apple wird von Apple betrieben.</p>",
            ),
            (
                "Aufbewahrung und Rechte (EU)",
                "<p>Wir verarbeiten Konto- und Cloud-Save-Daten zur Erbringung des gewünschten Dienstes. Wir speichern sie, solange das Konto besteht oder bis zur Löschanfrage. Kontakt: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>",
            ),
            ("Kinder", "<p>Wir erheben wissentlich keine Daten von Kindern. Die Nutzung folgt den App-Store-Altersfreigaben.</p>"),
            ("Änderungen", "<p>Änderungen veröffentlichen wir auf dieser Seite mit neuem Datum.</p>"),
        ],
    },
}


# EULA / Terms of Use — required next to Privacy for App Store auto-renewable IAP (3.1.2).
_TERMS_EN_SECTIONS = [
    (
        "Agreement",
        "<p>These Terms of Use (“Terms”) govern your use of the XP Pocket iOS app and related services at <a href=\"https://xppocket.app\">xppocket.app</a> and <a href=\"https://api.xppocket.app\">api.xppocket.app</a>. By downloading or using XP Pocket, you agree to these Terms. If you do not agree, do not use the app.</p>",
    ),
    (
        "What XP Pocket is",
        "<p>XP Pocket is a player for RPG Maker / RGSS games that <strong>you</strong> import. The app does not include commercial games, ROMs, or third-party game content. You are solely responsible for having the rights to any files you import or play.</p>",
    ),
    (
        "License to use the app",
        "<p>We grant you a personal, non-exclusive, non-transferable license to use XP Pocket on Apple devices you own or control, subject to the App Store terms and these Terms. XP Pocket includes open-source components under licenses such as the GPL; those licenses continue to apply to the corresponding source.</p>",
    ),
    (
        "Accounts",
        "<p>Playing does not require an account. Optional Sign in with Apple enables Pro entitlements, cloud save, and related account features. You may delete your XP Pocket account in Settings → Account → Delete account. Deleting your account removes your profile and cloud saves from our servers. It does not cancel an App Store subscription.</p>",
    ),
    (
        "Subscriptions and In-App Purchases",
        "<p>XP Pocket Pro is an optional auto-renewable subscription sold through Apple In-App Purchase. Price and period are shown in the app before purchase and charged to your Apple ID. Payment is billed by Apple. Manage or cancel in Settings → Apple ID → Subscriptions. Restoring purchases is available in the app. Refunds are handled by Apple under Apple’s policies.</p>",
    ),
    (
        "Ads (free tier)",
        "<p>The free tier may show advertisements (for example via Google AdMob) outside active gameplay. Pro removes those ads according to the benefits listed in the paywall.</p>",
    ),
    (
        "Acceptable use",
        "<p>You agree not to misuse the service, attempt unauthorized access to our systems, upload unlawful content, or use XP Pocket to distribute material you do not have rights to. We may suspend accounts that abuse the service.</p>",
    ),
    (
        "Disclaimer",
        "<p>XP Pocket is provided “as is”. Compatibility with individual games varies. We do not warrant uninterrupted operation or that every imported game will run correctly. To the maximum extent permitted by law, we are not liable for lost saves, lost data, or damages arising from use of the app or imported content.</p>",
    ),
    (
        "Privacy",
        "<p>Our <a href=\"https://xppocket.app/privacy\">Privacy Policy</a> explains what data we process. By using account or cloud features, you also agree to that policy.</p>",
    ),
    (
        "Changes",
        "<p>We may update these Terms by posting a new version on this page with an updated date. Continued use after changes constitutes acceptance where permitted by law.</p>",
    ),
    (
        "Contact",
        "<p>Questions: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>",
    ),
]

_TERMS_ES_SECTIONS = [
    (
        "Acuerdo",
        "<p>Estos Términos de uso (“Términos”) regulan el uso de la app XP Pocket para iOS y los servicios en <a href=\"https://xppocket.app\">xppocket.app</a> y <a href=\"https://api.xppocket.app\">api.xppocket.app</a>. Al descargar o usar XP Pocket, aceptas estos Términos. Si no estás de acuerdo, no uses la app.</p>",
    ),
    (
        "Qué es XP Pocket",
        "<p>XP Pocket es un reproductor de juegos RPG Maker / RGSS que <strong>tú</strong> importas. La app no incluye juegos comerciales, ROMs ni contenido de terceros. Eres responsable de tener derechos sobre los archivos que importes o juegues.</p>",
    ),
    (
        "Licencia de uso",
        "<p>Te concedemos una licencia personal, no exclusiva e intransferible para usar XP Pocket en dispositivos Apple que poseas o controles, sujeta a los términos de App Store y a estos Términos. XP Pocket incluye componentes open source (p. ej. GPL); esas licencias siguen aplicando a su código.</p>",
    ),
    (
        "Cuentas",
        "<p>Jugar no requiere cuenta. El Sign in with Apple opcional habilita Pro, cloud save y funciones de cuenta. Puedes borrar tu cuenta en Ajustes → Account → Delete account. Eso elimina el perfil y los cloud saves en nuestros servidores. No cancela una suscripción de App Store.</p>",
    ),
    (
        "Suscripciones y compras in-app",
        "<p>XP Pocket Pro es una suscripción auto-renovable opcional vendida mediante In-App Purchase de Apple. El precio y el periodo se muestran en la app antes de comprar y se cargan a tu Apple ID. Apple factura el pago. Gestiona o cancela en Ajustes → Apple ID → Suscripciones. La restauración de compras está en la app. Los reembolsos los gestiona Apple.</p>",
    ),
    (
        "Anuncios (tier gratis)",
        "<p>El tier gratis puede mostrar anuncios (p. ej. Google AdMob) fuera del gameplay activo. Pro elimina esos anuncios según los beneficios del paywall.</p>",
    ),
    (
        "Uso aceptable",
        "<p>No debes abusar del servicio, intentar acceso no autorizado, subir contenido ilícito ni usar XP Pocket para distribuir material sin derechos. Podemos suspender cuentas que abusen del servicio.</p>",
    ),
    (
        "Aviso de responsabilidad",
        "<p>XP Pocket se ofrece “tal cual”. La compatibilidad varía. No garantizamos funcionamiento ininterrumpido ni que todo juego importado funcione. En la medida permitida por la ley, no respondemos por partidas perdidas, datos perdidos o daños derivados del uso de la app o del contenido importado.</p>",
    ),
    (
        "Privacidad",
        "<p>Nuestra <a href=\"https://xppocket.app/privacy\">Política de privacidad</a> explica qué datos tratamos. Al usar cuenta o cloud save, también aceptas esa política.</p>",
    ),
    (
        "Cambios",
        "<p>Podemos actualizar estos Términos publicando una nueva versión en esta página con fecha actualizada. El uso continuado tras los cambios supone aceptación cuando la ley lo permita.</p>",
    ),
    (
        "Contacto",
        "<p>Consultas: <a href=\"mailto:support@xppocket.app\">support@xppocket.app</a>.</p>",
    ),
]

TERMS = {
    "es": {
        "title": "Términos de uso — XP Pocket",
        "description": "Términos de uso y suscripción de XP Pocket para iOS.",
        "back": "← XP Pocket",
        "h1": "Términos de uso",
        "updated": "Última actualización: 26 de agosto de 2026",
        "sections": _TERMS_ES_SECTIONS,
    },
    "en": {
        "title": "Terms of Use — XP Pocket",
        "description": "XP Pocket terms of use and subscription terms for iOS.",
        "back": "← XP Pocket",
        "h1": "Terms of Use",
        "updated": "Last updated: 26 August 2026",
        "sections": _TERMS_EN_SECTIONS,
    },
    "pt": {
        "title": "Termos de uso — XP Pocket",
        "description": "Termos de uso e assinatura do XP Pocket para iOS.",
        "back": "← XP Pocket",
        "h1": "Termos de uso",
        "updated": "Last updated: 26 August 2026 (English text)",
        "sections": _TERMS_EN_SECTIONS,
    },
    "fr": {
        "title": "Conditions d'utilisation — XP Pocket",
        "description": "Conditions d'utilisation et d'abonnement de XP Pocket pour iOS.",
        "back": "← XP Pocket",
        "h1": "Conditions d'utilisation",
        "updated": "Last updated: 26 August 2026 (English text)",
        "sections": _TERMS_EN_SECTIONS,
    },
    "de": {
        "title": "Nutzungsbedingungen — XP Pocket",
        "description": "Nutzungs- und Abo-Bedingungen von XP Pocket für iOS.",
        "back": "← XP Pocket",
        "h1": "Nutzungsbedingungen",
        "updated": "Last updated: 26 August 2026 (English text)",
        "sections": _TERMS_EN_SECTIONS,
    },
}


def hreflang_tags(page: str) -> str:
    lines = []
    for lang in LANGS:
        lines.append(
            f'  <link rel="alternate" hreflang="{HTML_LANG[lang]}" href="{BASE}{path_for(lang, page)}">'
        )
    lines.append(f'  <link rel="alternate" hreflang="x-default" href="{BASE}{path_for("es", page)}">')
    return "\n".join(lines)


def head_common(lang: str, page: str, title: str, description: str, keywords: str = "") -> str:
    canonical = BASE + path_for(lang, page)
    kw = f'\n  <meta name="keywords" content="{keywords}">' if keywords else ""
    css = asset(lang, "site.css") + "?v=20260825c"
    return f"""  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <meta name="description" content="{description}">{kw}
  <meta name="author" content="XP Pocket">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="{canonical}">
{hreflang_tags(page)}
  <link rel="icon" href="/assets/logo.png" type="image/png">
  <link rel="apple-touch-icon" href="/assets/logo.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Figtree:wght@400;500;600;700;800&family=Outfit:wght@500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="{css}">"""


def guide_cards(lang: str) -> str:
    ui = GUIDE_UI[lang]
    cards = []
    for slug in GUIDE_ORDER:
        g = GUIDES[slug][lang]
        url = path_for(lang, f"guide:{slug}")
        cards.append(
            f'<a class="guide-card" href="{url}">'
            f"<h3>{g['card_title']}</h3>"
            f"<p>{g['card_blurb']}</p>"
            f'<span class="guide-card-cta">{ui["read_guide"]} →</span>'
            f"</a>"
        )
    return '<div class="guide-grid">' + "".join(cards) + "</div>"


def render_home(lang: str) -> str:
    t = HOME[lang]
    ui = GUIDE_UI[lang]
    features = "".join(
        f'<article class="feature"><h3>{h}</h3><p>{p}</p></article>' for h, p in t["features"]
    )
    seo_blocks = []
    for strong, body in t["seo_blocks"]:
        if strong:
            seo_blocks.append(f"<p><strong>{strong}</strong> {body}</p>")
        else:
            seo_blocks.append(f"<p>{body}</p>")
    faqs = "".join(
        f"<details{' open' if i == 0 else ''}><summary>{q}</summary><p>{a}</p></details>"
        for i, (q, a) in enumerate(t["faqs"])
    )
    faq_schema_entities = ",\n".join(
        f"""{{
        "@type": "Question",
        "name": {json_str(q)},
        "acceptedAnswer": {{ "@type": "Answer", "text": {json_str(a)} }}
      }}"""
        for q, a in t["faq_schema"]
    )
    chips = "".join(
        f'<span class="chip">{c}</span>'
        for c in ["RPG Maker XP", "RPG Maker VX", "RPG Maker VX Ace", "Pokémon Essentials", "mkxp / RGSS"]
    )
    return f"""<!DOCTYPE html>
<html lang="{HTML_LANG[lang]}">
<head>
{head_common(lang, "home", t["title"], t["description"], t["keywords"])}
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="XP Pocket">
  <meta property="og:url" content="{BASE}{path_for(lang, "home")}">
  <meta property="og:title" content="{t["og_title"]}">
  <meta property="og:description" content="{t["og_description"]}">
  <meta property="og:image" content="{BASE}/assets/logo.png">
  <meta property="og:locale" content="{LOCALE[lang]}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{t["og_title"]}">
  <meta name="twitter:description" content="{t["og_description"]}">
  <meta name="twitter:image" content="{BASE}/assets/logo.png">
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "name": "XP Pocket",
    "operatingSystem": "iOS 26 or later",
    "applicationCategory": "GameApplication",
    "description": {json_str(t["schema_desc"])},
    "url": "{BASE}{path_for(lang, "home")}",
    "image": "{BASE}/assets/logo.png",
    "offers": {{ "@type": "Offer", "price": "0", "priceCurrency": "EUR", "availability": "https://schema.org/PreOrder" }},
    "author": {{ "@type": "Organization", "name": "XP Pocket", "url": "{BASE}/" }}
  }}
  </script>
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {faq_schema_entities}
    ]
  }}
  </script>
</head>
<body>
  <header class="hero">
{top_nav(lang, "home")}
    <div class="hero-inner">
      <div class="hero-copy">
        <p class="brand">XP Pocket</p>
        <h1 class="headline">{t["headline"]}</h1>
        <p class="lede">{t["lede"]}</p>
        <div class="cta-row">
          <a class="btn btn-primary" href="#disponibilidad">{t["cta_store"]}</a>
          <a class="btn btn-ghost" href="#features">{t["cta_features"]}</a>
          <p class="cta-note">{t["cta_note"]}</p>
        </div>
      </div>
      <div class="hero-visual" aria-hidden="true">
        <div class="device-stage">
          <div class="glow"></div>
          <div class="phone">
            <div class="phone-screen">
              <div class="status-bar"><span>9:41</span><span class="island"></span><span class="sb-icons"></span></div>
              <div class="lib-toolbar">
                <span class="lib-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"/></svg></span>
                <h2>{t["lib_title"]}</h2>
                <span class="lib-icon add" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg></span>
              </div>
              <div class="lib-search-row">
                <div class="lib-search"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg></div>
                <span class="lib-chip" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 15V3M7 15l-3-3M7 15l3-3M17 9v12M17 9l-3 3M17 9l3 3"/></svg></span>
                <span class="lib-chip" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg></span>
              </div>
              <div class="game-list">
                <div class="game-row"><div class="game-cover c1"></div><span class="game-name">Royal</span><span class="game-play" aria-hidden="true"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg></span></div>
                <div class="game-row"><div class="game-cover c2"></div><span class="game-name">Añil</span><span class="game-play" aria-hidden="true"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg></span></div>
                <div class="game-row"><div class="game-cover c3"></div><span class="game-name">Essentials</span><span class="game-play" aria-hidden="true"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg></span></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </header>
  <main>
    <section class="section" id="features">
      <p class="section-kicker">{t["feat_kicker"]}</p>
      <h2>{t["feat_h2"]}</h2>
      <p>{t["feat_p"]}</p>
      <div class="feature-list">{features}</div>
    </section>
    <section class="section" id="essentials">
      <p class="section-kicker">{t["seo_kicker"]}</p>
      <h2>{t["seo_h2"]}</h2>
      <p>{t["seo_intro"]}</p>
      <div class="seo-copy">{"".join(seo_blocks)}</div>
      <div class="faq" id="faq">{faqs}</div>
      <p class="disclaimer">{t["disclaimer"]}</p>
    </section>
    <section class="section" id="guias">
      <p class="section-kicker">{ui["guides_nav"]}</p>
      <h2>{ui["index_h1"]}</h2>
      <p>{ui["index_lede"]}</p>
      {guide_cards(lang)}
    </section>
    <section class="section compat" id="disponibilidad">
      <p class="section-kicker">{t["compat_kicker"]}</p>
      <h2>{t["compat_h2"]}</h2>
      <p>{t["compat_p"]}</p>
      <div class="chips">{chips}</div>
      <p class="legal-note">{t["legal_note"]}</p>
    </section>
  </main>
{site_footer(lang)}
</body>
</html>
"""


def json_str(s: str) -> str:
    import json

    return json.dumps(s, ensure_ascii=False)


def render_privacy(lang: str) -> str:
    t = PRIVACY[lang]
    ui = GUIDE_UI[lang]
    body = "".join(f"<h2>{h}</h2>\n    {html}\n" for h, html in t["sections"])
    return f"""<!DOCTYPE html>
<html lang="{HTML_LANG[lang]}">
<head>
{head_common(lang, "privacy", t["title"], t["description"])}
  <meta property="og:type" content="website">
  <meta property="og:title" content="{t["title"]}">
  <meta property="og:description" content="{t["description"]}">
  <meta property="og:url" content="{BASE}{path_for(lang, "privacy")}">
  <meta property="og:locale" content="{LOCALE[lang]}">
</head>
<body class="doc-page">
  <div class="doc-wrap">
    <div class="doc-top">
      <a class="quiet" href="{path_for(lang, "home")}">{t["back"]}</a>
      <div class="nav-right">
        {lang_switcher(lang, "privacy")}
        <a class="quiet" href="{path_for(lang, "guides")}">{ui["guides_nav"]}</a>
        <a class="quiet" href="{path_for(lang, "terms")}">{HOME[lang]["footer_terms"]}</a>
      </div>
    </div>
    <h1>{t["h1"]}</h1>
    <p class="updated">{t["updated"]}</p>
    {body}
  </div>
</body>
</html>
"""


def render_terms(lang: str) -> str:
    t = TERMS[lang]
    ui = GUIDE_UI[lang]
    body = "".join(f"<h2>{h}</h2>\n    {html}\n" for h, html in t["sections"])
    return f"""<!DOCTYPE html>
<html lang="{HTML_LANG[lang]}">
<head>
{head_common(lang, "terms", t["title"], t["description"])}
  <meta property="og:type" content="website">
  <meta property="og:title" content="{t["title"]}">
  <meta property="og:description" content="{t["description"]}">
  <meta property="og:url" content="{BASE}{path_for(lang, "terms")}">
  <meta property="og:locale" content="{LOCALE[lang]}">
</head>
<body class="doc-page">
  <div class="doc-wrap">
    <div class="doc-top">
      <a class="quiet" href="{path_for(lang, "home")}">{t["back"]}</a>
      <div class="nav-right">
        {lang_switcher(lang, "terms")}
        <a class="quiet" href="{path_for(lang, "privacy")}">{ui["privacy_nav"]}</a>
      </div>
    </div>
    <h1>{t["h1"]}</h1>
    <p class="updated">{t["updated"]}</p>
    {body}
  </div>
</body>
</html>
"""


def render_guides_index(lang: str) -> str:
    ui = GUIDE_UI[lang]
    return f"""<!DOCTYPE html>
<html lang="{HTML_LANG[lang]}">
<head>
{head_common(lang, "guides", ui["index_title"], ui["index_description"])}
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="XP Pocket">
  <meta property="og:title" content="{ui["index_title"]}">
  <meta property="og:description" content="{ui["index_description"]}">
  <meta property="og:url" content="{BASE}{path_for(lang, "guides")}">
  <meta property="og:image" content="{BASE}/assets/logo.png">
  <meta property="og:locale" content="{LOCALE[lang]}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{ui["index_title"]}">
  <meta name="twitter:description" content="{ui["index_description"]}">
  <meta name="twitter:image" content="{BASE}/assets/logo.png">
</head>
<body class="doc-page">
  <div class="doc-wrap doc-wrap-wide">
    <div class="doc-top">
      <a class="quiet" href="{path_for(lang, "home")}">{ui["back"]}</a>
      <div class="nav-right">
        {lang_switcher(lang, "guides")}
        <a class="quiet" href="{path_for(lang, "privacy")}">{ui["privacy_nav"]}</a>
      </div>
    </div>
    <p class="section-kicker">{ui["guides_nav"]}</p>
    <h1>{ui["index_h1"]}</h1>
    <p class="doc-lede">{ui["index_lede"]}</p>
    {guide_cards(lang)}
    <p class="disclaimer">{ui["disclaimer"]}</p>
    <p class="doc-cta"><a class="btn btn-primary" href="{path_for(lang, "home")}">{ui["cta_home"]}</a></p>
  </div>
{site_footer(lang)}
</body>
</html>
"""


def render_guide(lang: str, slug: str) -> str:
    ui = GUIDE_UI[lang]
    g = GUIDES[slug][lang]
    page = f"guide:{slug}"
    steps_html = "".join(
        f'<li class="guide-step"><h2>{title}</h2>{body}</li>' for title, body in g["steps"]
    )
    faqs = "".join(
        f"<details{' open' if i == 0 else ''}><summary>{q}</summary><p>{a}</p></details>"
        for i, (q, a) in enumerate(g["faqs"])
    )
    howto_steps = ",\n".join(
        f"""{{
        "@type": "HowToStep",
        "position": {i + 1},
        "name": {json_str(title)},
        "text": {json_str(body.replace("<p>", "").replace("</p>", "").replace("<strong>", "").replace("</strong>", ""))}
      }}"""
        for i, (title, body) in enumerate(g["steps"])
    )
    faq_schema = ",\n".join(
        f"""{{
        "@type": "Question",
        "name": {json_str(q)},
        "acceptedAnswer": {{ "@type": "Answer", "text": {json_str(a)} }}
      }}"""
        for q, a in g["faqs"]
    )
    related = "".join(
        f'<li><a href="{path_for(lang, f"guide:{other}")}">{GUIDES[other][lang]["card_title"]}</a></li>'
        for other in GUIDE_ORDER
        if other != slug
    )
    return f"""<!DOCTYPE html>
<html lang="{HTML_LANG[lang]}">
<head>
{head_common(lang, page, g["title"], g["description"], g["keywords"])}
  <meta property="og:type" content="article">
  <meta property="og:site_name" content="XP Pocket">
  <meta property="og:title" content="{g["title"]}">
  <meta property="og:description" content="{g["description"]}">
  <meta property="og:url" content="{BASE}{path_for(lang, page)}">
  <meta property="og:image" content="{BASE}/assets/logo.png">
  <meta property="og:locale" content="{LOCALE[lang]}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{g["title"]}">
  <meta name="twitter:description" content="{g["description"]}">
  <meta name="twitter:image" content="{BASE}/assets/logo.png">
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "HowTo",
    "name": {json_str(g["h1"])},
    "description": {json_str(g["description"])},
    "url": "{BASE}{path_for(lang, page)}",
    "image": "{BASE}/assets/logo.png",
    "step": [
      {howto_steps}
    ]
  }}
  </script>
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {faq_schema}
    ]
  }}
  </script>
</head>
<body class="doc-page">
  <div class="doc-wrap">
    <div class="doc-top">
      <a class="quiet" href="{path_for(lang, "guides")}">← {ui["guides_nav"]}</a>
      <div class="nav-right">
        {lang_switcher(lang, page)}
        <a class="quiet" href="{path_for(lang, "home")}">XP Pocket</a>
      </div>
    </div>
    <p class="section-kicker">{ui["steps_kicker"]}</p>
    <h1>{g["h1"]}</h1>
    <p class="doc-lede">{g["lede"]}</p>
    <ol class="guide-steps">{steps_html}</ol>
    <p class="section-kicker">{ui["faq_kicker"]}</p>
    <div class="faq">{faqs}</div>
    <p class="disclaimer">{ui["disclaimer"]}</p>
    <aside class="related-guides">
      <h2>{ui["related"]}</h2>
      <ul>{related}</ul>
    </aside>
    <p class="doc-cta">
      <a class="btn btn-primary" href="{path_for(lang, "home")}">{ui["cta_home"]}</a>
      <a class="btn btn-ghost" href="{path_for(lang, "guides")}">{ui["guides_nav"]}</a>
    </p>
  </div>
{site_footer(lang)}
</body>
</html>
"""


def write_page(lang: str, page: str, content: str) -> Path:
    pref = PREFIX[lang]
    if page == "home":
        out = ROOT / pref / "index.html" if pref else ROOT / "index.html"
    elif page == "privacy":
        out = ROOT / pref / "privacy.html" if pref else ROOT / "privacy.html"
    elif page == "terms":
        out = ROOT / pref / "terms.html" if pref else ROOT / "terms.html"
    elif page == "guides":
        seg = GUIDE_SEGMENT[lang]
        out = ROOT / pref / seg / "index.html" if pref else ROOT / seg / "index.html"
    elif page.startswith("guide:"):
        slug = page.split(":", 1)[1]
        seg = GUIDE_SEGMENT[lang]
        out = ROOT / pref / seg / f"{slug}.html" if pref else ROOT / seg / f"{slug}.html"
    else:
        raise ValueError(f"unknown page: {page}")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")
    return out


def write_sitemap() -> None:
    urls = []
    for lang in LANGS:
        pages = ["home", "privacy", "terms", "guides"] + [f"guide:{s}" for s in GUIDE_ORDER]
        for page in pages:
            loc = BASE + path_for(lang, page)
            if page == "home" and lang == "es":
                priority = "1.0"
            elif page == "home" or page.startswith("guide:"):
                priority = "0.8"
            elif page == "guides":
                priority = "0.7"
            else:
                priority = "0.5"
            urls.append(
                f"""  <url>
    <loc>{loc}</loc>
    <changefreq>weekly</changefreq>
    <priority>{priority}</priority>
  </url>"""
            )
    (ROOT / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "\n".join(urls)
        + "\n</urlset>\n",
        encoding="utf-8",
    )


def main() -> None:
    for lang in LANGS:
        write_page(lang, "home", render_home(lang))
        write_page(lang, "privacy", render_privacy(lang))
        write_page(lang, "terms", render_terms(lang))
        write_page(lang, "guides", render_guides_index(lang))
        for slug in GUIDE_ORDER:
            write_page(lang, f"guide:{slug}", render_guide(lang, slug))
        print(f"wrote {lang} home + privacy + terms + {len(GUIDE_ORDER)} guides")
    write_sitemap()
    print("wrote sitemap.xml")


if __name__ == "__main__":
    main()
