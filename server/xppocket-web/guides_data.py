"""SEO guide pages for xppocket.app (evergreen how-tos)."""

from __future__ import annotations

# URL segment per language (same guide slug under each).
GUIDE_SEGMENT = {
    "es": "guias",
    "en": "guides",
    "pt": "guias",
    "fr": "guides",
    "de": "anleitungen",
}

GUIDE_ORDER = (
    "pokemon-essentials-iphone",
    "pokemon-anil-iphone",
    "import-rpg-maker",
    "touch-controls",
)

GUIDE_UI = {
    "es": {
        "guides_nav": "Guías",
        "privacy_nav": "Privacidad",
        "back": "← XP Pocket",
        "index_title": "Guías XP Pocket — Essentials, Añil y RPG Maker en iPhone",
        "index_description": "Guías para jugar Pokémon Essentials, Pokémon Añil y fan games RPG Maker en iPhone e iPad con XP Pocket. Tú importas los archivos.",
        "index_h1": "Guías XP Pocket",
        "index_lede": "Cómo importar y jugar fan games RPG Maker y proyectos Essentials en iOS. Sin descargas de juegos: usas tus propios archivos.",
        "related": "Más guías",
        "cta_home": "Ir a XP Pocket",
        "cta_store": "Próximamente en App Store",
        "steps_kicker": "Paso a paso",
        "faq_kicker": "Preguntas frecuentes",
        "disclaimer": "Pokémon y marcas relacionadas son propiedad de Nintendo, Game Freak y The Pokémon Company. XP Pocket no está afiliado. No incluimos ni distribuimos juegos, ROMs ni assets con copyright de terceros. Solo ejecuta archivos que tú importas y de los que tengas derechos.",
        "footer_privacy": "Privacidad",
        "footer_guides": "Guías",
        "footer_support": "Soporte",
        "read_guide": "Leer guía",
    },
    "en": {
        "guides_nav": "Guides",
        "privacy_nav": "Privacy",
        "back": "← XP Pocket",
        "index_title": "XP Pocket Guides — Essentials, Añil & RPG Maker on iPhone",
        "index_description": "Guides to play Pokémon Essentials, Pokémon Añil, and RPG Maker fan games on iPhone and iPad with XP Pocket. You import the files.",
        "index_h1": "XP Pocket guides",
        "index_lede": "How to import and play RPG Maker fan games and Essentials projects on iOS. No game downloads — you use your own files.",
        "related": "More guides",
        "cta_home": "Go to XP Pocket",
        "cta_store": "Coming soon to the App Store",
        "steps_kicker": "Step by step",
        "faq_kicker": "FAQ",
        "disclaimer": "Pokémon and related marks are owned by Nintendo, Game Freak, and The Pokémon Company. XP Pocket is not affiliated. We do not include or distribute games, ROMs, or third-party copyrighted assets. The app only runs files you import and have rights to use.",
        "footer_privacy": "Privacy",
        "footer_guides": "Guides",
        "footer_support": "Support",
        "read_guide": "Read guide",
    },
    "pt": {
        "guides_nav": "Guias",
        "privacy_nav": "Privacidade",
        "back": "← XP Pocket",
        "index_title": "Guias XP Pocket — Essentials, Añil e RPG Maker no iPhone",
        "index_description": "Guias para jogar Pokémon Essentials, Pokémon Añil e fan games RPG Maker no iPhone e iPad com o XP Pocket. Você importa os ficheiros.",
        "index_h1": "Guias XP Pocket",
        "index_lede": "Como importar e jogar fan games RPG Maker e projetos Essentials no iOS. Sem downloads de jogos: usa os seus ficheiros.",
        "related": "Mais guias",
        "cta_home": "Ir ao XP Pocket",
        "cta_store": "Em breve na App Store",
        "steps_kicker": "Passo a passo",
        "faq_kicker": "Perguntas frequentes",
        "disclaimer": "Pokémon e marcas relacionadas são propriedade da Nintendo, Game Freak e The Pokémon Company. O XP Pocket não é afiliado. Não incluímos nem distribuímos jogos, ROMs ou assets com copyright. A app só executa ficheiros que você importa e de que tenha direitos.",
        "footer_privacy": "Privacidade",
        "footer_guides": "Guias",
        "footer_support": "Suporte",
        "read_guide": "Ler guia",
    },
    "fr": {
        "guides_nav": "Guides",
        "privacy_nav": "Confidentialité",
        "back": "← XP Pocket",
        "index_title": "Guides XP Pocket — Essentials, Añil et RPG Maker sur iPhone",
        "index_description": "Guides pour jouer à Pokémon Essentials, Pokémon Añil et aux fan games RPG Maker sur iPhone et iPad avec XP Pocket. Vous importez les fichiers.",
        "index_h1": "Guides XP Pocket",
        "index_lede": "Comment importer et jouer à des fan games RPG Maker et projets Essentials sur iOS. Pas de téléchargement de jeux : vous utilisez vos fichiers.",
        "related": "Autres guides",
        "cta_home": "Aller sur XP Pocket",
        "cta_store": "Bientôt sur l'App Store",
        "steps_kicker": "Pas à pas",
        "faq_kicker": "FAQ",
        "disclaimer": "Pokémon et les marques associées appartiennent à Nintendo, Game Freak et The Pokémon Company. XP Pocket n'est pas affilié. Nous n'incluons ni ne distribuons de jeux, ROMs ou assets protégés. L'app n'exécute que les fichiers que vous importez et dont vous avez les droits.",
        "footer_privacy": "Confidentialité",
        "footer_guides": "Guides",
        "footer_support": "Support",
        "read_guide": "Lire le guide",
    },
    "de": {
        "guides_nav": "Anleitungen",
        "privacy_nav": "Datenschutz",
        "back": "← XP Pocket",
        "index_title": "XP Pocket Anleitungen — Essentials, Añil & RPG Maker auf dem iPhone",
        "index_description": "Anleitungen zum Spielen von Pokémon Essentials, Pokémon Añil und RPG-Maker-Fan-Games auf iPhone und iPad mit XP Pocket. Du importierst die Dateien.",
        "index_h1": "XP Pocket Anleitungen",
        "index_lede": "So importierst und spielst du RPG-Maker-Fan-Games und Essentials-Projekte auf iOS. Keine Spiel-Downloads — du nutzt deine eigenen Dateien.",
        "related": "Weitere Anleitungen",
        "cta_home": "Zu XP Pocket",
        "cta_store": "Bald im App Store",
        "steps_kicker": "Schritt für Schritt",
        "faq_kicker": "FAQ",
        "disclaimer": "Pokémon und verwandte Marken gehören Nintendo, Game Freak und The Pokémon Company. XP Pocket ist nicht verbunden. Wir enthalten und verteilen keine Spiele, ROMs oder urheberrechtlich geschützte Assets. Die App führt nur Dateien aus, die du importierst und nutzen darfst.",
        "footer_privacy": "Datenschutz",
        "footer_guides": "Anleitungen",
        "footer_support": "Support",
        "read_guide": "Anleitung lesen",
    },
}

# Each guide: card blurb + full page content per lang.
GUIDES = {
    "pokemon-essentials-iphone": {
        "es": {
            "card_title": "Pokémon Essentials en iPhone",
            "card_blurb": "Cómo ejecutar proyectos Essentials en iOS con XP Pocket.",
            "title": "Cómo jugar Pokémon Essentials en iPhone — XP Pocket",
            "description": "Guía para jugar Pokémon Essentials en iPhone e iPad. Importa tu proyecto RPG Maker / Essentials en XP Pocket. Sin juegos incluidos.",
            "keywords": "Pokémon Essentials iPhone, Pokémon Essentials iOS, jugar Essentials iPhone, mkxp iOS, XP Pocket",
            "h1": "Cómo jugar Pokémon Essentials en iPhone",
            "lede": "XP Pocket es un reproductor iOS para juegos RPG Maker y proyectos basados en Pokémon Essentials. Tú aportas la carpeta o el archivo del juego; la app no descarga ni incluye títulos.",
            "steps": [
                (
                    "Consigue tus archivos del juego",
                    "<p>Necesitas una copia del proyecto Essentials / RPG Maker XP de la que tengas derechos (carpeta del juego o archivo comprimido). XP Pocket <strong>no ofrece descargas</strong> de fan games ni de assets con copyright.</p>",
                ),
                (
                    "Instala XP Pocket",
                    "<p>Cuando esté disponible en la App Store, instálalo en un iPhone o iPad con iOS 26 o posterior. Puedes jugar sin cuenta.</p>",
                ),
                (
                    "Importa el proyecto",
                    "<p>Abre la biblioteca y usa el botón de añadir. Elige la carpeta o el archivo del juego desde Archivos, iCloud Drive u otra ubicación. El título aparece en tu biblioteca on‑device.</p>",
                ),
                (
                    "Juega con controles táctiles",
                    "<p>Lanza el juego y ajusta el layout táctil si lo necesitas. Puedes guardar partidas en el dispositivo; el cloud save es opcional con cuenta Apple y Pro.</p>",
                ),
            ],
            "faqs": [
                (
                    "¿XP Pocket incluye Pokémon Essentials?",
                    "No. Es un reproductor: ejecuta proyectos que tú importas. No empaquetamos Essentials ni fan games.",
                ),
                (
                    "¿Qué motores / RGSS son compatibles?",
                    "El motor mkxp‑z cubre RPG Maker XP, VX y VX Ace (RGSS). Muchos juegos Essentials van sobre XP.",
                ),
                (
                    "¿Funciona en iPad?",
                    "Sí. Misma app en iPhone e iPad; importa y juega on‑device.",
                ),
            ],
        },
        "en": {
            "card_title": "Pokémon Essentials on iPhone",
            "card_blurb": "How to run Essentials projects on iOS with XP Pocket.",
            "title": "How to play Pokémon Essentials on iPhone — XP Pocket",
            "description": "Guide to play Pokémon Essentials on iPhone and iPad. Import your RPG Maker / Essentials project into XP Pocket. No games included.",
            "keywords": "Pokémon Essentials iPhone, Pokémon Essentials iOS, play Essentials iPhone, mkxp iOS, XP Pocket",
            "h1": "How to play Pokémon Essentials on iPhone",
            "lede": "XP Pocket is an iOS player for RPG Maker games and Pokémon Essentials–based projects. You bring the game folder or archive; the app does not download or bundle titles.",
            "steps": [
                (
                    "Get your game files",
                    "<p>You need a copy of the Essentials / RPG Maker XP project you have rights to (game folder or archive). XP Pocket <strong>does not offer downloads</strong> of fan games or copyrighted assets.</p>",
                ),
                (
                    "Install XP Pocket",
                    "<p>When it is on the App Store, install it on an iPhone or iPad running iOS 26 or later. You can play without an account.</p>",
                ),
                (
                    "Import the project",
                    "<p>Open the library and tap add. Pick the game folder or archive from Files, iCloud Drive, or another location. The title appears in your on‑device library.</p>",
                ),
                (
                    "Play with touch controls",
                    "<p>Launch the game and tweak the touch layout if needed. Saves stay on device; cloud save is optional with Sign in with Apple and Pro.</p>",
                ),
            ],
            "faqs": [
                (
                    "Does XP Pocket include Pokémon Essentials?",
                    "No. It is a player: it runs projects you import. We do not ship Essentials or fan games.",
                ),
                (
                    "Which engines / RGSS are supported?",
                    "The mkxp‑z engine covers RPG Maker XP, VX, and VX Ace (RGSS). Many Essentials games target XP.",
                ),
                (
                    "Does it work on iPad?",
                    "Yes. Same app on iPhone and iPad; import and play on‑device.",
                ),
            ],
        },
        "pt": {
            "card_title": "Pokémon Essentials no iPhone",
            "card_blurb": "Como executar projetos Essentials no iOS com o XP Pocket.",
            "title": "Como jogar Pokémon Essentials no iPhone — XP Pocket",
            "description": "Guia para jogar Pokémon Essentials no iPhone e iPad. Importe o seu projeto RPG Maker / Essentials no XP Pocket. Sem jogos incluídos.",
            "keywords": "Pokémon Essentials iPhone, Pokémon Essentials iOS, jogar Essentials iPhone, mkxp iOS, XP Pocket",
            "h1": "Como jogar Pokémon Essentials no iPhone",
            "lede": "O XP Pocket é um leitor iOS para jogos RPG Maker e projetos baseados em Pokémon Essentials. Você traz a pasta ou o arquivo; a app não descarrega nem inclui títulos.",
            "steps": [
                (
                    "Obtenha os ficheiros do jogo",
                    "<p>Precisa de uma cópia do projeto Essentials / RPG Maker XP de que tenha direitos. O XP Pocket <strong>não oferece downloads</strong> de fan games nem de assets com copyright.</p>",
                ),
                (
                    "Instale o XP Pocket",
                    "<p>Quando estiver na App Store, instale num iPhone ou iPad com iOS 26 ou posterior. Pode jogar sem conta.</p>",
                ),
                (
                    "Importe o projeto",
                    "<p>Abra a biblioteca e use adicionar. Escolha a pasta ou o arquivo em Ficheiros, iCloud Drive ou outra localização.</p>",
                ),
                (
                    "Jogue com controlos táteis",
                    "<p>Inicie o jogo e ajuste o layout tátil se precisar. Os saves ficam no dispositivo; cloud save é opcional.</p>",
                ),
            ],
            "faqs": [
                (
                    "O XP Pocket inclui Pokémon Essentials?",
                    "Não. É um leitor: executa projetos que você importa.",
                ),
                (
                    "Que motores / RGSS são compatíveis?",
                    "O motor mkxp‑z cobre RPG Maker XP, VX e VX Ace (RGSS).",
                ),
                (
                    "Funciona no iPad?",
                    "Sim. A mesma app no iPhone e iPad.",
                ),
            ],
        },
        "fr": {
            "card_title": "Pokémon Essentials sur iPhone",
            "card_blurb": "Comment lancer des projets Essentials sur iOS avec XP Pocket.",
            "title": "Comment jouer à Pokémon Essentials sur iPhone — XP Pocket",
            "description": "Guide pour jouer à Pokémon Essentials sur iPhone et iPad. Importez votre projet RPG Maker / Essentials dans XP Pocket. Aucun jeu inclus.",
            "keywords": "Pokémon Essentials iPhone, Pokémon Essentials iOS, jouer Essentials iPhone, mkxp iOS, XP Pocket",
            "h1": "Comment jouer à Pokémon Essentials sur iPhone",
            "lede": "XP Pocket est un lecteur iOS pour jeux RPG Maker et projets basés sur Pokémon Essentials. Vous apportez le dossier ou l'archive ; l'app ne télécharge ni n'inclut de titres.",
            "steps": [
                (
                    "Préparez vos fichiers de jeu",
                    "<p>Il vous faut une copie du projet Essentials / RPG Maker XP dont vous avez les droits. XP Pocket <strong>ne propose pas de téléchargements</strong> de fan games ni d'assets protégés.</p>",
                ),
                (
                    "Installez XP Pocket",
                    "<p>Une fois sur l'App Store, installez-le sur un iPhone ou iPad sous iOS 26 ou plus. Vous pouvez jouer sans compte.</p>",
                ),
                (
                    "Importez le projet",
                    "<p>Ouvrez la bibliothèque et utilisez ajouter. Choisissez le dossier ou l'archive depuis Fichiers, iCloud Drive, etc.</p>",
                ),
                (
                    "Jouez avec les contrôles tactiles",
                    "<p>Lancez le jeu et ajustez le layout tactile si besoin. Les sauvegardes restent sur l'appareil ; le cloud save est optionnel.</p>",
                ),
            ],
            "faqs": [
                (
                    "XP Pocket inclut-il Pokémon Essentials ?",
                    "Non. C'est un lecteur : il exécute les projets que vous importez.",
                ),
                (
                    "Quels moteurs / RGSS sont pris en charge ?",
                    "Le moteur mkxp‑z couvre RPG Maker XP, VX et VX Ace (RGSS).",
                ),
                (
                    "Ça marche sur iPad ?",
                    "Oui. La même app sur iPhone et iPad.",
                ),
            ],
        },
        "de": {
            "card_title": "Pokémon Essentials auf dem iPhone",
            "card_blurb": "So spielst du Essentials-Projekte auf iOS mit XP Pocket.",
            "title": "Pokémon Essentials auf dem iPhone spielen — XP Pocket",
            "description": "Anleitung: Pokémon Essentials auf iPhone und iPad spielen. Importiere dein RPG-Maker-/Essentials-Projekt in XP Pocket. Keine Spiele enthalten.",
            "keywords": "Pokémon Essentials iPhone, Pokémon Essentials iOS, Essentials iPhone spielen, mkxp iOS, XP Pocket",
            "h1": "Pokémon Essentials auf dem iPhone spielen",
            "lede": "XP Pocket ist ein iOS-Player für RPG-Maker-Spiele und Pokémon-Essentials-Projekte. Du bringst Ordner oder Archiv mit; die App lädt keine Titel herunter und enthält keine.",
            "steps": [
                (
                    "Spiel-Dateien bereithalten",
                    "<p>Du brauchst eine Kopie des Essentials-/RPG-Maker-XP-Projekts, an dem du Rechte hast. XP Pocket <strong>bietet keine Downloads</strong> von Fan-Games oder geschützten Assets an.</p>",
                ),
                (
                    "XP Pocket installieren",
                    "<p>Sobald es im App Store ist, auf iPhone oder iPad mit iOS 26 oder neuer installieren. Spielen geht ohne Konto.</p>",
                ),
                (
                    "Projekt importieren",
                    "<p>Bibliothek öffnen und hinzufügen tippen. Ordner oder Archiv aus Dateien, iCloud Drive usw. wählen.</p>",
                ),
                (
                    "Mit Touch-Steuerung spielen",
                    "<p>Spiel starten und Touch-Layout bei Bedarf anpassen. Speicherstände bleiben auf dem Gerät; Cloud-Save ist optional.</p>",
                ),
            ],
            "faqs": [
                (
                    "Enthält XP Pocket Pokémon Essentials?",
                    "Nein. Es ist ein Player: Es führt Projekte aus, die du importierst.",
                ),
                (
                    "Welche Engines / RGSS werden unterstützt?",
                    "Die mkxp‑z-Engine deckt RPG Maker XP, VX und VX Ace (RGSS) ab.",
                ),
                (
                    "Funktioniert es auf dem iPad?",
                    "Ja. Dieselbe App auf iPhone und iPad.",
                ),
            ],
        },
    },
    "pokemon-anil-iphone": {
        "es": {
            "card_title": "Pokémon Añil en iPhone",
            "card_blurb": "Importa tus archivos de Añil y juega en iOS.",
            "title": "Cómo jugar Pokémon Añil en iPhone — XP Pocket",
            "description": "Guía para jugar Pokémon Añil en iPhone e iPad con XP Pocket. Importa tus propios archivos. La app no descarga ni redistribuye Añil.",
            "keywords": "Pokémon Añil iPhone, Pokémon Añil iOS, jugar Añil iPhone, Pokémon Essentials español, XP Pocket",
            "h1": "Cómo jugar Pokémon Añil en iPhone",
            "lede": "Si ya tienes Pokémon Añil (u otro fan game en español basado en Essentials), puedes cargarlo en XP Pocket. La app solo ejecuta lo que tú importas; no ofrece el juego.",
            "steps": [
                (
                    "Usa tus propios archivos de Añil",
                    "<p>Debes disponer de una copia del juego de la que tengas derechos. XP Pocket <strong>no enlaza, no descarga y no redistribuye</strong> Pokémon Añil ni ningún otro título.</p>",
                ),
                (
                    "Prepara la carpeta o el archivo",
                    "<p>Ten la carpeta del juego o un archivo compatible listo en Archivos / iCloud. Los proyectos tipo Essentials sobre RPG Maker XP son el caso habitual.</p>",
                ),
                (
                    "Importa en XP Pocket",
                    "<p>En la biblioteca, añade el juego desde tu dispositivo. Aparecerá como cualquier otro título importado.</p>",
                ),
                (
                    "Juega y guarda en el dispositivo",
                    "<p>Abre Añil, configura el layout táctil y guarda la partida en local. El cloud save es opcional si usas cuenta Apple y Pro.</p>",
                ),
            ],
            "faqs": [
                (
                    "¿Puedo descargar Añil desde XP Pocket?",
                    "No. Nunca. Solo importas archivos que ya tienes.",
                ),
                (
                    "¿Está afiliado a Nintendo o a los autores de Añil?",
                    "No. XP Pocket es un reproductor independiente. Pokémon es marca de Nintendo / Game Freak / TPC.",
                ),
                (
                    "¿Sirve para otros fan games en español?",
                    "Sí, si son proyectos RPG Maker / Essentials compatibles y tienes derechos sobre los archivos.",
                ),
            ],
        },
        "en": {
            "card_title": "Pokémon Añil on iPhone",
            "card_blurb": "Import your Añil files and play on iOS.",
            "title": "How to play Pokémon Añil on iPhone — XP Pocket",
            "description": "Guide to play Pokémon Añil on iPhone and iPad with XP Pocket. Import your own files. The app does not download or redistribute Añil.",
            "keywords": "Pokémon Añil iPhone, Pokémon Añil iOS, play Añil iPhone, Pokémon Essentials Spanish, XP Pocket",
            "h1": "How to play Pokémon Añil on iPhone",
            "lede": "If you already have Pokémon Añil (or another Essentials-based fan game), you can load it in XP Pocket. The app only runs what you import; it does not offer the game.",
            "steps": [
                (
                    "Use your own Añil files",
                    "<p>You must have a copy you have rights to. XP Pocket <strong>does not link, download, or redistribute</strong> Pokémon Añil or any other title.</p>",
                ),
                (
                    "Prepare the folder or archive",
                    "<p>Have the game folder or a compatible archive ready in Files / iCloud. Essentials-style projects on RPG Maker XP are the usual case.</p>",
                ),
                (
                    "Import into XP Pocket",
                    "<p>In the library, add the game from your device. It appears like any other imported title.</p>",
                ),
                (
                    "Play and save on device",
                    "<p>Open Añil, set up the touch layout, and save locally. Cloud save is optional with Sign in with Apple and Pro.</p>",
                ),
            ],
            "faqs": [
                (
                    "Can I download Añil from XP Pocket?",
                    "No. Never. You only import files you already have.",
                ),
                (
                    "Is XP Pocket affiliated with Nintendo or Añil’s authors?",
                    "No. It is an independent player. Pokémon is a trademark of Nintendo / Game Freak / TPC.",
                ),
                (
                    "Does it work for other Spanish fan games?",
                    "Yes, if they are compatible RPG Maker / Essentials projects and you have rights to the files.",
                ),
            ],
        },
        "pt": {
            "card_title": "Pokémon Añil no iPhone",
            "card_blurb": "Importe os seus ficheiros de Añil e jogue no iOS.",
            "title": "Como jogar Pokémon Añil no iPhone — XP Pocket",
            "description": "Guia para jogar Pokémon Añil no iPhone e iPad com o XP Pocket. Importe os seus ficheiros. A app não descarrega nem redistribui Añil.",
            "keywords": "Pokémon Añil iPhone, Pokémon Añil iOS, jogar Añil iPhone, Pokémon Essentials, XP Pocket",
            "h1": "Como jogar Pokémon Añil no iPhone",
            "lede": "Se já tem Pokémon Añil (ou outro fan game baseado em Essentials), pode carregá-lo no XP Pocket. A app só executa o que você importa.",
            "steps": [
                (
                    "Use os seus ficheiros de Añil",
                    "<p>Tem de ter uma cópia de que tenha direitos. O XP Pocket <strong>não liga, não descarrega e não redistribui</strong> Pokémon Añil.</p>",
                ),
                (
                    "Prepare a pasta ou o arquivo",
                    "<p>Tenha a pasta do jogo ou um arquivo compatível em Ficheiros / iCloud.</p>",
                ),
                (
                    "Importe no XP Pocket",
                    "<p>Na biblioteca, adicione o jogo a partir do dispositivo.</p>",
                ),
                (
                    "Jogue e guarde no dispositivo",
                    "<p>Abra Añil, configure o layout tátil e guarde localmente. Cloud save é opcional.</p>",
                ),
            ],
            "faqs": [
                (
                    "Posso descarregar Añil no XP Pocket?",
                    "Não. Nunca. Só importa ficheiros que já tem.",
                ),
                (
                    "É afiliado à Nintendo?",
                    "Não. É um leitor independente.",
                ),
                (
                    "Serve para outros fan games?",
                    "Sim, se forem projetos RPG Maker / Essentials compatíveis e tiver direitos.",
                ),
            ],
        },
        "fr": {
            "card_title": "Pokémon Añil sur iPhone",
            "card_blurb": "Importez vos fichiers Añil et jouez sur iOS.",
            "title": "Comment jouer à Pokémon Añil sur iPhone — XP Pocket",
            "description": "Guide pour jouer à Pokémon Añil sur iPhone et iPad avec XP Pocket. Importez vos fichiers. L'app ne télécharge ni ne redistribue Añil.",
            "keywords": "Pokémon Añil iPhone, Pokémon Añil iOS, jouer Añil iPhone, Pokémon Essentials, XP Pocket",
            "h1": "Comment jouer à Pokémon Añil sur iPhone",
            "lede": "Si vous avez déjà Pokémon Añil (ou un autre fan game basé sur Essentials), vous pouvez le charger dans XP Pocket. L'app n'exécute que ce que vous importez.",
            "steps": [
                (
                    "Utilisez vos propres fichiers Añil",
                    "<p>Vous devez disposer d'une copie dont vous avez les droits. XP Pocket <strong>ne lie pas, ne télécharge pas et ne redistribue pas</strong> Pokémon Añil.</p>",
                ),
                (
                    "Préparez le dossier ou l'archive",
                    "<p>Ayez le dossier du jeu ou une archive compatible dans Fichiers / iCloud.</p>",
                ),
                (
                    "Importez dans XP Pocket",
                    "<p>Dans la bibliothèque, ajoutez le jeu depuis l'appareil.</p>",
                ),
                (
                    "Jouez et sauvegardez sur l'appareil",
                    "<p>Ouvrez Añil, réglez le layout tactile et sauvegardez en local. Le cloud save est optionnel.</p>",
                ),
            ],
            "faqs": [
                (
                    "Puis-je télécharger Añil depuis XP Pocket ?",
                    "Non. Jamais. Vous importez uniquement des fichiers que vous avez déjà.",
                ),
                (
                    "Est-ce affilié à Nintendo ?",
                    "Non. C'est un lecteur indépendant.",
                ),
                (
                    "Ça marche pour d'autres fan games ?",
                    "Oui, s'ils sont compatibles RPG Maker / Essentials et que vous avez les droits.",
                ),
            ],
        },
        "de": {
            "card_title": "Pokémon Añil auf dem iPhone",
            "card_blurb": "Importiere deine Añil-Dateien und spiele auf iOS.",
            "title": "Pokémon Añil auf dem iPhone spielen — XP Pocket",
            "description": "Anleitung: Pokémon Añil auf iPhone und iPad mit XP Pocket. Importiere eigene Dateien. Die App lädt Añil nicht herunter und verteilt es nicht.",
            "keywords": "Pokémon Añil iPhone, Pokémon Añil iOS, Añil iPhone spielen, Pokémon Essentials, XP Pocket",
            "h1": "Pokémon Añil auf dem iPhone spielen",
            "lede": "Wenn du Pokémon Añil (oder ein anderes Essentials-Fan-Game) bereits hast, kannst du es in XP Pocket laden. Die App führt nur aus, was du importierst.",
            "steps": [
                (
                    "Eigene Añil-Dateien nutzen",
                    "<p>Du brauchst eine Kopie, an der du Rechte hast. XP Pocket <strong>verlinkt, lädt und verteilt Pokémon Añil nicht</strong>.</p>",
                ),
                (
                    "Ordner oder Archiv vorbereiten",
                    "<p>Spielordner oder kompatibles Archiv in Dateien / iCloud bereithalten.</p>",
                ),
                (
                    "In XP Pocket importieren",
                    "<p>In der Bibliothek das Spiel vom Gerät hinzufügen.</p>",
                ),
                (
                    "Spielen und lokal speichern",
                    "<p>Añil starten, Touch-Layout einrichten und lokal speichern. Cloud-Save ist optional.</p>",
                ),
            ],
            "faqs": [
                (
                    "Kann ich Añil über XP Pocket herunterladen?",
                    "Nein. Niemals. Du importierst nur Dateien, die du schon hast.",
                ),
                (
                    "Ist das mit Nintendo verbunden?",
                    "Nein. Es ist ein unabhängiger Player.",
                ),
                (
                    "Geht es auch für andere Fan-Games?",
                    "Ja, wenn sie kompatible RPG-Maker-/Essentials-Projekte sind und du Rechte hast.",
                ),
            ],
        },
    },
    "import-rpg-maker": {
        "es": {
            "card_title": "Importar juegos RPG Maker",
            "card_blurb": "Carpetas, archivos y biblioteca on‑device.",
            "title": "Cómo importar un juego RPG Maker en iPhone — XP Pocket",
            "description": "Guía para importar juegos RPG Maker XP, VX o VX Ace en iPhone e iPad con XP Pocket. Carpeta o archivo; biblioteca en el dispositivo.",
            "keywords": "importar RPG Maker iPhone, RPG Maker iOS, mkxp iOS, RPG Maker XP iPhone, XP Pocket",
            "h1": "Cómo importar un juego RPG Maker en iPhone",
            "lede": "XP Pocket convierte tu iPhone en un reproductor mkxp‑z: importas el juego, se queda en la biblioteca del dispositivo y lo lanzas cuando quieras.",
            "steps": [
                (
                    "Comprueba el formato",
                    "<p>Suelen funcionar proyectos RPG Maker XP, VX y VX Ace (RGSS), incluidos muchos fan games y juegos Essentials. Debes tener derechos sobre esos archivos.</p>",
                ),
                (
                    "Copia el juego al iPhone o iPad",
                    "<p>Usa AirDrop, iCloud Drive, Files u otro método para tener la carpeta o el archivo en el dispositivo antes de importar.</p>",
                ),
                (
                    "Añade desde la biblioteca",
                    "<p>En XP Pocket, pulsa añadir y selecciona la carpeta o el archivo. El título se lista en tu biblioteca local.</p>",
                ),
                (
                    "Organiza y juega",
                    "<p>Abre el juego desde la lista. Puedes tener varios títulos importados; no hay catálogo remoto de juegos.</p>",
                ),
            ],
            "faqs": [
                (
                    "¿Hace falta cuenta?",
                    "No para importar y jugar. Sign in with Apple es opcional (cloud save y Pro).",
                ),
                (
                    "¿Dónde se guardan los juegos?",
                    "En el dispositivo, en el espacio de la app. Tú controlas qué importas y qué borras.",
                ),
                (
                    "¿Puedo importar un ZIP?",
                    "Sí, si el archivo es un proyecto compatible. También puedes importar la carpeta descomprimida.",
                ),
            ],
        },
        "en": {
            "card_title": "Import RPG Maker games",
            "card_blurb": "Folders, archives, and on‑device library.",
            "title": "How to import an RPG Maker game on iPhone — XP Pocket",
            "description": "Guide to import RPG Maker XP, VX, or VX Ace games on iPhone and iPad with XP Pocket. Folder or archive; library on device.",
            "keywords": "import RPG Maker iPhone, RPG Maker iOS, mkxp iOS, RPG Maker XP iPhone, XP Pocket",
            "h1": "How to import an RPG Maker game on iPhone",
            "lede": "XP Pocket turns your iPhone into an mkxp‑z player: you import the game, it stays in the on‑device library, and you launch it whenever you want.",
            "steps": [
                (
                    "Check the format",
                    "<p>RPG Maker XP, VX, and VX Ace (RGSS) projects usually work, including many fan games and Essentials titles. You must have rights to those files.</p>",
                ),
                (
                    "Copy the game to iPhone or iPad",
                    "<p>Use AirDrop, iCloud Drive, Files, or another method so the folder or archive is on the device before importing.</p>",
                ),
                (
                    "Add from the library",
                    "<p>In XP Pocket, tap add and select the folder or archive. The title appears in your local library.</p>",
                ),
                (
                    "Organize and play",
                    "<p>Open the game from the list. You can keep multiple imported titles; there is no remote game catalog.</p>",
                ),
            ],
            "faqs": [
                (
                    "Do I need an account?",
                    "Not to import and play. Sign in with Apple is optional (cloud save and Pro).",
                ),
                (
                    "Where are games stored?",
                    "On device, in the app’s space. You control what you import and delete.",
                ),
                (
                    "Can I import a ZIP?",
                    "Yes, if the archive is a compatible project. You can also import an unzipped folder.",
                ),
            ],
        },
        "pt": {
            "card_title": "Importar jogos RPG Maker",
            "card_blurb": "Pastas, arquivos e biblioteca no dispositivo.",
            "title": "Como importar um jogo RPG Maker no iPhone — XP Pocket",
            "description": "Guia para importar jogos RPG Maker XP, VX ou VX Ace no iPhone e iPad com o XP Pocket.",
            "keywords": "importar RPG Maker iPhone, RPG Maker iOS, mkxp iOS, XP Pocket",
            "h1": "Como importar um jogo RPG Maker no iPhone",
            "lede": "O XP Pocket transforma o iPhone num leitor mkxp‑z: você importa o jogo, fica na biblioteca do dispositivo e inicia quando quiser.",
            "steps": [
                (
                    "Verifique o formato",
                    "<p>Projetos RPG Maker XP, VX e VX Ace (RGSS) costumam funcionar. Tem de ter direitos sobre os ficheiros.</p>",
                ),
                (
                    "Copie o jogo para o dispositivo",
                    "<p>Use AirDrop, iCloud Drive, Ficheiros ou outro método antes de importar.</p>",
                ),
                (
                    "Adicione na biblioteca",
                    "<p>No XP Pocket, toque em adicionar e escolha a pasta ou o arquivo.</p>",
                ),
                (
                    "Organize e jogue",
                    "<p>Abra o jogo na lista. Pode ter vários títulos importados; não há catálogo remoto.</p>",
                ),
            ],
            "faqs": [
                (
                    "É preciso conta?",
                    "Não para importar e jogar. Sign in with Apple é opcional.",
                ),
                (
                    "Onde ficam os jogos?",
                    "No dispositivo, no espaço da app.",
                ),
                (
                    "Posso importar um ZIP?",
                    "Sim, se for um projeto compatível.",
                ),
            ],
        },
        "fr": {
            "card_title": "Importer des jeux RPG Maker",
            "card_blurb": "Dossiers, archives et bibliothèque sur l'appareil.",
            "title": "Comment importer un jeu RPG Maker sur iPhone — XP Pocket",
            "description": "Guide pour importer des jeux RPG Maker XP, VX ou VX Ace sur iPhone et iPad avec XP Pocket.",
            "keywords": "importer RPG Maker iPhone, RPG Maker iOS, mkxp iOS, XP Pocket",
            "h1": "Comment importer un jeu RPG Maker sur iPhone",
            "lede": "XP Pocket transforme votre iPhone en lecteur mkxp‑z : vous importez le jeu, il reste dans la bibliothèque de l'appareil.",
            "steps": [
                (
                    "Vérifiez le format",
                    "<p>Les projets RPG Maker XP, VX et VX Ace (RGSS) fonctionnent en général. Vous devez avoir les droits sur ces fichiers.</p>",
                ),
                (
                    "Copiez le jeu sur l'appareil",
                    "<p>Utilisez AirDrop, iCloud Drive, Fichiers, etc. avant d'importer.</p>",
                ),
                (
                    "Ajoutez depuis la bibliothèque",
                    "<p>Dans XP Pocket, utilisez ajouter et sélectionnez le dossier ou l'archive.</p>",
                ),
                (
                    "Organisez et jouez",
                    "<p>Ouvrez le jeu dans la liste. Pas de catalogue distant de jeux.</p>",
                ),
            ],
            "faqs": [
                (
                    "Faut-il un compte ?",
                    "Non pour importer et jouer. Sign in with Apple est optionnel.",
                ),
                (
                    "Où sont stockés les jeux ?",
                    "Sur l'appareil, dans l'espace de l'app.",
                ),
                (
                    "Puis-je importer un ZIP ?",
                    "Oui, si l'archive est un projet compatible.",
                ),
            ],
        },
        "de": {
            "card_title": "RPG-Maker-Spiele importieren",
            "card_blurb": "Ordner, Archive und Bibliothek auf dem Gerät.",
            "title": "RPG-Maker-Spiel auf dem iPhone importieren — XP Pocket",
            "description": "Anleitung: RPG Maker XP, VX oder VX Ace auf iPhone und iPad mit XP Pocket importieren.",
            "keywords": "RPG Maker iPhone importieren, RPG Maker iOS, mkxp iOS, XP Pocket",
            "h1": "RPG-Maker-Spiel auf dem iPhone importieren",
            "lede": "XP Pocket macht dein iPhone zum mkxp‑z-Player: Du importierst das Spiel, es bleibt in der Gerätebibliothek.",
            "steps": [
                (
                    "Format prüfen",
                    "<p>RPG Maker XP, VX und VX Ace (RGSS) funktionieren in der Regel. Du brauchst Nutzungsrechte an den Dateien.</p>",
                ),
                (
                    "Spiel aufs Gerät kopieren",
                    "<p>Per AirDrop, iCloud Drive, Dateien usw. Ordner oder Archiv bereitstellen.</p>",
                ),
                (
                    "Aus der Bibliothek hinzufügen",
                    "<p>In XP Pocket hinzufügen tippen und Ordner oder Archiv wählen.</p>",
                ),
                (
                    "Organisieren und spielen",
                    "<p>Spiel aus der Liste starten. Kein Remote-Katalog.</p>",
                ),
            ],
            "faqs": [
                (
                    "Brauche ich ein Konto?",
                    "Nicht zum Importieren und Spielen. Sign in with Apple ist optional.",
                ),
                (
                    "Wo liegen die Spiele?",
                    "Auf dem Gerät im App-Speicher.",
                ),
                (
                    "Kann ich eine ZIP importieren?",
                    "Ja, wenn es ein kompatibles Projekt ist.",
                ),
            ],
        },
    },
    "touch-controls": {
        "es": {
            "card_title": "Controles táctiles",
            "card_blurb": "Layouts por juego y packs de la comunidad.",
            "title": "Controles táctiles en XP Pocket — iPhone y iPad",
            "description": "Cómo usar y personalizar layouts táctiles en XP Pocket para RPG Maker y Essentials en iPhone e iPad. Perfiles por juego y layouts comunitarios.",
            "keywords": "controles táctiles RPG Maker iPhone, layout táctil mkxp, XP Pocket controles, gamepad táctil iOS",
            "h1": "Controles táctiles en XP Pocket",
            "lede": "Los fan games de PC no traen gamepad en pantalla. XP Pocket añade layouts táctiles que puedes adaptar por juego y, si quieres, ampliar con packs de la comunidad.",
            "steps": [
                (
                    "Abre un juego importado",
                    "<p>Los controles aparecen sobre el juego. Puedes pausar o entrar en ajustes de layout según la UI de la app.</p>",
                ),
                (
                    "Ajusta el layout al título",
                    "<p>Mueve, redimensiona u oculta botones para que encajen con el género (aventura, combate por turnos, etc.). Guarda un perfil por juego si lo prefieres.</p>",
                ),
                (
                    "Prueba layouts de la comunidad",
                    "<p>La app puede listar packs desde la API pública. No hace falta cuenta para explorar; son overlays, no juegos.</p>",
                ),
                (
                    "Juega a pantalla completa",
                    "<p>Cuando el layout te encaje, sigue jugando on‑device. El objetivo es que Essentials y RPG Maker se sientan naturales en iPhone e iPad.</p>",
                ),
            ],
            "faqs": [
                (
                    "¿Hay que pagar por los layouts?",
                    "Jugar e importar no exige cuenta. Algunas funciones Pro (p. ej. cloud save) son opcionales.",
                ),
                (
                    "¿Los layouts incluyen juegos?",
                    "No. Solo mapas de botones / overlays. Los juegos los importas tú.",
                ),
                (
                    "¿Sirve para iPad?",
                    "Sí. Puedes aprovechar más espacio de pantalla en iPad.",
                ),
            ],
        },
        "en": {
            "card_title": "Touch controls",
            "card_blurb": "Per-game layouts and community packs.",
            "title": "Touch controls in XP Pocket — iPhone and iPad",
            "description": "How to use and customize touch layouts in XP Pocket for RPG Maker and Essentials on iPhone and iPad. Per-game profiles and community layouts.",
            "keywords": "RPG Maker touch controls iPhone, mkxp touch layout, XP Pocket controls, iOS on-screen gamepad",
            "h1": "Touch controls in XP Pocket",
            "lede": "PC fan games do not ship with an on-screen gamepad. XP Pocket adds touch layouts you can tailor per game and, optionally, extend with community packs.",
            "steps": [
                (
                    "Open an imported game",
                    "<p>Controls appear over the game. Pause or open layout settings from the app UI as needed.</p>",
                ),
                (
                    "Tune the layout to the title",
                    "<p>Move, resize, or hide buttons to match the genre (adventure, turn-based combat, etc.). Save a per-game profile if you like.</p>",
                ),
                (
                    "Try community layouts",
                    "<p>The app can list packs from the public API. No account is required to browse; they are overlays, not games.</p>",
                ),
                (
                    "Play full screen",
                    "<p>Once the layout fits, keep playing on‑device. The goal is for Essentials and RPG Maker to feel natural on iPhone and iPad.</p>",
                ),
            ],
            "faqs": [
                (
                    "Do I pay for layouts?",
                    "Playing and importing do not require an account. Some Pro features (e.g. cloud save) are optional.",
                ),
                (
                    "Do layouts include games?",
                    "No. Only button maps / overlays. You import the games yourself.",
                ),
                (
                    "Does it work on iPad?",
                    "Yes. You can use the larger screen on iPad.",
                ),
            ],
        },
        "pt": {
            "card_title": "Controlos táteis",
            "card_blurb": "Layouts por jogo e packs da comunidade.",
            "title": "Controlos táteis no XP Pocket — iPhone e iPad",
            "description": "Como usar e personalizar layouts táteis no XP Pocket para RPG Maker e Essentials no iPhone e iPad.",
            "keywords": "controlos táteis RPG Maker iPhone, layout tátil mkxp, XP Pocket",
            "h1": "Controlos táteis no XP Pocket",
            "lede": "Os fan games de PC não trazem gamepad no ecrã. O XP Pocket adiciona layouts táteis que pode adaptar por jogo.",
            "steps": [
                (
                    "Abra um jogo importado",
                    "<p>Os controlos aparecem sobre o jogo. Pause ou abra os ajustes de layout conforme a UI.</p>",
                ),
                (
                    "Ajuste o layout ao título",
                    "<p>Mova, redimensione ou oculte botões. Guarde um perfil por jogo se quiser.</p>",
                ),
                (
                    "Experimente layouts da comunidade",
                    "<p>A app pode listar packs na API pública. São overlays, não jogos.</p>",
                ),
                (
                    "Jogue em ecrã inteiro",
                    "<p>Quando o layout encaixar, continue a jogar no dispositivo.</p>",
                ),
            ],
            "faqs": [
                (
                    "É preciso pagar pelos layouts?",
                    "Jogar e importar não exige conta. Funções Pro são opcionais.",
                ),
                (
                    "Os layouts incluem jogos?",
                    "Não. Só mapas de botões. Você importa os jogos.",
                ),
                (
                    "Funciona no iPad?",
                    "Sim.",
                ),
            ],
        },
        "fr": {
            "card_title": "Contrôles tactiles",
            "card_blurb": "Layouts par jeu et packs communautaires.",
            "title": "Contrôles tactiles dans XP Pocket — iPhone et iPad",
            "description": "Comment utiliser et personnaliser les layouts tactiles dans XP Pocket pour RPG Maker et Essentials sur iPhone et iPad.",
            "keywords": "contrôles tactiles RPG Maker iPhone, layout tactile mkxp, XP Pocket",
            "h1": "Contrôles tactiles dans XP Pocket",
            "lede": "Les fan games PC n'ont pas de manette à l'écran. XP Pocket ajoute des layouts tactiles que vous adaptez par jeu.",
            "steps": [
                (
                    "Ouvrez un jeu importé",
                    "<p>Les contrôles s'affichent sur le jeu. Mettez en pause ou ouvrez les réglages de layout selon l'UI.</p>",
                ),
                (
                    "Ajustez le layout au titre",
                    "<p>Déplacez, redimensionnez ou masquez des boutons. Enregistrez un profil par jeu si vous voulez.</p>",
                ),
                (
                    "Essayez les layouts communautaires",
                    "<p>L'app peut lister des packs via l'API publique. Ce sont des overlays, pas des jeux.</p>",
                ),
                (
                    "Jouez en plein écran",
                    "<p>Quand le layout convient, continuez sur l'appareil.</p>",
                ),
            ],
            "faqs": [
                (
                    "Faut-il payer pour les layouts ?",
                    "Jouer et importer ne nécessitent pas de compte. Les fonctions Pro sont optionnelles.",
                ),
                (
                    "Les layouts incluent-ils des jeux ?",
                    "Non. Uniquement des cartes de boutons. Vous importez les jeux.",
                ),
                (
                    "Ça marche sur iPad ?",
                    "Oui.",
                ),
            ],
        },
        "de": {
            "card_title": "Touch-Steuerung",
            "card_blurb": "Layouts pro Spiel und Community-Packs.",
            "title": "Touch-Steuerung in XP Pocket — iPhone und iPad",
            "description": "So nutzt und passt du Touch-Layouts in XP Pocket für RPG Maker und Essentials auf iPhone und iPad an.",
            "keywords": "Touch-Steuerung RPG Maker iPhone, mkxp Touch-Layout, XP Pocket",
            "h1": "Touch-Steuerung in XP Pocket",
            "lede": "PC-Fan-Games haben kein On-Screen-Gamepad. XP Pocket ergänzt Touch-Layouts, die du pro Spiel anpassen kannst.",
            "steps": [
                (
                    "Importiertes Spiel öffnen",
                    "<p>Die Steuerung liegt über dem Spiel. Pause oder Layout-Einstellungen je nach UI öffnen.</p>",
                ),
                (
                    "Layout an den Titel anpassen",
                    "<p>Buttons verschieben, skalieren oder ausblenden. Optional Profil pro Spiel speichern.</p>",
                ),
                (
                    "Community-Layouts testen",
                    "<p>Die App kann Packs über die öffentliche API listen. Es sind Overlays, keine Spiele.</p>",
                ),
                (
                    "Vollbild spielen",
                    "<p>Wenn das Layout passt, weiter on‑device spielen.</p>",
                ),
            ],
            "faqs": [
                (
                    "Muss ich für Layouts zahlen?",
                    "Spielen und Importieren brauchen kein Konto. Pro-Funktionen sind optional.",
                ),
                (
                    "Enthalten Layouts Spiele?",
                    "Nein. Nur Button-Maps. Du importierst die Spiele.",
                ),
                (
                    "Geht es auf dem iPad?",
                    "Ja.",
                ),
            ],
        },
    },
}
