#!/usr/bin/env python3
"""Bygger nettsidene: kort startside, Design, Arkitektur, Lys og fargemåling og Alle funksjoner (nb og en).
Innholdet hentes fra de opprinnelige forsidene (webkilde/), så funksjonslistene står ordrett som før.

    python3 web/verktøy/lag_sider.py

Skriver sidene i web/<VERSJON> (nå 1.3; 1.2-sidene i web/1.2 er ferdige og bygges ikke på nytt). Tekst endres i
webkilde/ eller her, ikke i de ferdige sidene (de skrives over). Det som er nytt i versjonen, merkes med N; det som
var nytt i forrige versjon, står med N12 (tomt), så merket kan flyttes tilbake om det trengs."""
import pathlib
import re

VERSJON = '1.3'
# Merke for det som var nytt i 1.2 – ikke lenger nytt.
N12 = ''

S = str(pathlib.Path(__file__).resolve().parent)
W = str(pathlib.Path(__file__).resolve().parent.parent / VERSJON)

kilde = {'nb': open(f'{S}/webkilde/index.html').read(), 'en': open(f'{S}/webkilde/en/index.html').read()}

# Sidepar nb ↔ en
PAR = {'index.html': 'index.html', 'design.html': 'design.html', 'arkitektur.html': 'architecture.html',
       'lys.html': 'light.html', 'funksjoner.html': 'features.html', 'plattformer.html': 'platforms.html', 'filament.html': 'filament.html', 'support.html': 'support.html',
       'privacy.html': 'privacy.html', 'terms.html': 'terms.html', 'methods.html': 'methods.html'}
TIL_NB = {v: k for k, v in PAR.items()}

T = {
    'nb': dict(
        nytt=f'Nytt i {VERSJON}', hopp='Hopp til hovedinnhold', hovedmeny='Hovedmeny', bunnmeny='Bunnmeny', språk='Språk',
        nav=[('design.html', 'Design'), ('arkitektur.html', 'Arkitektur'), ('filament.html', '3D-print'), ('plattformer.html', 'Plattformer'), ('support.html', 'Støtte')],
        bunn=[('index.html', 'Om appen'), ('design.html', 'Design'), ('arkitektur.html', 'Arkitektur'), ('plattformer.html', 'Plattformer'), ('filament.html', '3D-print'),
              ('funksjoner.html', 'Alle funksjoner'), ('lys.html', 'Lys og fargemåling'), ('support.html', 'Støtte'),
              ('methods.html', 'Metoder og kilder'), ('privacy.html', 'Personvern'), ('terms.html', 'Vilkår')],
        annet='English', annet_lang='en', locale='nb_NO',
        utvikler='Kolorist er utviklet av Eivind Arnstein Johansen – Institutt for design, NTNU.',
        copyright='© 2026 Eivind Arnstein Johansen. Apple, iPhone, iPad, Mac, iCloud, Siri og Apple Intelligence er varemerker for Apple Inc.',
    ),
    'en': dict(
        nytt=f'New in {VERSJON}', hopp='Skip to main content', hovedmeny='Main menu', bunnmeny='Footer menu', språk='Language',
        nav=[('design.html', 'Design'), ('architecture.html', 'Architecture'), ('filament.html', '3D printing'), ('platforms.html', 'Platforms'), ('support.html', 'Support')],
        bunn=[('index.html', 'About'), ('design.html', 'Design'), ('architecture.html', 'Architecture'), ('platforms.html', 'Platforms'), ('filament.html', '3D printing'),
              ('features.html', 'All features'), ('light.html', 'Light and colour measurement'), ('support.html', 'Support'),
              ('methods.html', 'Methods and sources'), ('privacy.html', 'Privacy'), ('terms.html', 'Terms')],
        annet='Norsk', annet_lang='nb', locale='en_US',
        utvikler='Kolorist is developed by Eivind Arnstein Johansen – Department of Design, NTNU.',
        copyright='© 2026 Eivind Arnstein Johansen. Apple, iPhone, iPad, Mac, iCloud, Siri and Apple Intelligence are trademarks of Apple Inc.',
    ),
}


def url(lang, fil):
    nb = fil if lang == 'nb' else TIL_NB[fil]
    nbfil, enfil = nb, PAR[nb]
    nburl = 'https://kolorist.no/' + ('' if nbfil == 'index.html' else nbfil)
    enurl = 'https://kolorist.no/en/' + ('' if enfil == 'index.html' else enfil)
    return nburl, enurl


def annen_side(lang, fil):
    return ('en/' + PAR[fil]) if lang == 'nb' else ('../' + TIL_NB[fil])


def hovednav(lang, fil):
    t = T[lang]
    aktiv = ' aria-current="page"'
    li = '\n'.join(f'          <li><a href="{h}"{aktiv if h == fil else ""}>{n}</a></li>' for h, n in t['nav'])
    return f'<nav class="hovednav" aria-label="{t["hovedmeny"]}">\n        <ul>\n{li}\n        </ul>\n      </nav>'


def bunnnav(lang, fil):
    t = T[lang]
    li = '\n'.join(f'          <li><a href="{h}">{n}</a></li>' for h, n in t['bunn'])
    li += f'\n          <li><a href="{annen_side(lang, fil)}" hreflang="{t["annet_lang"]}" lang="{t["annet_lang"]}">{t["annet"]}</a></li>'
    return f'<nav aria-label="{t["bunnmeny"]}">\n        <ul>\n{li}\n        </ul>\n      </nav>'


def side(lang, fil, tittel, beskrivelse, innhold, karusell=False):
    t = T[lang]
    p = '' if lang == 'nb' else '../'
    nburl, enurl = url(lang, fil)
    egen = nburl if lang == 'nb' else enurl
    språkvalg = (f'<span aria-current="true" lang="nb">Norsk</span>\n        <a href="{annen_side(lang, fil)}" hreflang="en" lang="en">English</a>'
                 if lang == 'nb' else
                 f'<a href="{annen_side(lang, fil)}" hreflang="nb" lang="nb">Norsk</a>\n        <span aria-current="true" lang="en">English</span>')
    skript = f'\n  <script src="{p}assets/karusell.js?v=1" defer></script>' if karusell else ''
    return f'''<!doctype html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{tittel}</title>
  <meta name="description" content="{beskrivelse}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Kolorist">
  <meta property="og:title" content="{tittel}">
  <meta property="og:description" content="{beskrivelse}">
  <meta property="og:url" content="{egen}">
  <meta property="og:locale" content="{t['locale']}">
  <meta name="color-scheme" content="light dark">
  <meta name="referrer" content="no-referrer">
  <!-- Smart App Banner i Safari på iPhone/iPad -->
  <meta name="apple-itunes-app" content="app-id=6818636272">
  <link rel="icon" href="{p}assets/ikon.svg" type="image/svg+xml">
  <link rel="stylesheet" href="{p}assets/stil.css?v=6">
  <link rel="canonical" href="{egen}">
  <link rel="alternate" hreflang="nb" href="{nburl}">
  <link rel="alternate" hreflang="en" href="{enurl}">
  <link rel="alternate" hreflang="x-default" href="{nburl}">
</head>
<body>
  <a class="hopp" href="#hovedinnhold">{t['hopp']}</a>
  <div class="regnbuestripe" aria-hidden="true"></div>

  <header class="topp">
    <div class="topp-innhold">
      <a class="merkenavn" href="index.html">
        <img src="{p}assets/ikon.svg" alt="" width="32" height="32">
        Kolorist
      </a>
      {hovednav(lang, fil)}
      <nav class="sprakvalg" aria-label="{t['språk']}">
        {språkvalg}
      </nav>
    </div>
  </header>

  <main id="hovedinnhold" class="innhold" tabindex="-1">
{innhold.rstrip()}
  </main>

  <footer class="bunn">
    <div class="bunn-innhold">
      {bunnnav(lang, fil)}
      <p class="utvikler">{t['utvikler']}</p>
      <p>{t['copyright']}</p>
    </div>
  </footer>{skript}
</body>
</html>
'''


# ---------- Utdrag fra de opprinnelige sidene ----------

def kort(s):
    return {m.group(1): m.group(2).strip()
            for m in re.finditer(r'<article class="kort">\s*<h3>(.*?)</h3>(.*?)</article>', s, re.S)}


def lier(inner):
    return re.findall(r'<li>.*?</li>', inner, re.S)


def bilde(s, fil):
    return re.search(r'<img src="[^"]*/' + re.escape(fil) + r'[^"]*"[^>]*>|<img src="' + re.escape(fil) + r'[^"]*"[^>]*>', s).group(0)


NYE_BILDER = {
    ('nb', 'palettgrupper'): ('Paletter samlet i palettgruppen Landskap, med menyen for å skrive ut, lagre og kopiere hele gruppen', 'Palettgrupper'),
    ('en', 'palettgrupper'): ('Palettes gathered in the palette group Landscapes, with the menu for printing, saving and copying the whole group', 'Palette groups'),
    ('nb', 'monokrom'): ('Monokromatisk harmoni: seks toner av oransje langs en strek fra rik oransje til en mørk, mettet tone, i flaten for lyshet og metning', 'Monokromatisk'),
    ('en', 'monokrom'): ('Monochromatic harmony: six tones of orange along a line from rich orange to a dark, saturated tone, in the lightness and saturation field', 'Monochromatic'),
    ('nb', 'harmoni-aksent'): ('Harmoni: analog med komplementær aksent og naturlig lyshetsrekkefølge, vist på fargesirkelen', 'Analog med aksent'),
    ('en', 'harmoni-aksent'): ('Harmony: analogous with a complementary accent and natural lightness order, shown on the colour wheel', 'Analogous with accent'),
    ('nb', 'munsell'): ('Studio med en teglrød farge i Munsell-notasjon, 10R 5/8 – kulør, valør og kroma', 'Munsell'),
    ('en', 'munsell'): ('Studio with a brick-red colour in Munsell notation, 10R 5/8 – hue, value and chroma', 'Munsell'),
    ('nb', 'arkitektur-lys'): ('Lys under Vurdering: en teglrød farge på skjermen og i stua om kvelden, og under flere betraktningsforhold med fargeskiftet for hvert', 'Fargen under ulike betraktningsforhold'),
    ('en', 'arkitektur-lys'): ('Light under Assess: a brick-red colour on screen and in the living room in the evening, and in more viewing conditions with the colour shift for each', 'The colour in viewing conditions'),
    ('nb', 'palett-lys'): ('En palett i lys: fargen på skjermen øverst og i stua om kvelden nederst i hver rute, med fargeskiftet', 'Paletten i lys'),
    ('en', 'palett-lys'): ('A palette in light: the colour on screen at the top and in the living room in the evening at the bottom of each tile, with the colour shift', 'Palette in light'),
    ('nb', 'skriftkontrast'): ('Skriftkontrast i en palett: hver farge som tekst på de andre, med WCAG-kontrast og hvor mange fargepar som består', 'Skriftkontrast'),
    ('en', 'skriftkontrast'): ('Text contrast in a palette: each colour as text on the others, with WCAG contrast and how many colour pairs pass', 'Text contrast'),
}
NYE_BILDER.update({
    ('nb', 'filament'): ('Studio med «Filament: alle typer»: fargen og nærmeste filament, Atomic Filament Too Good to be Blue (PLA)', 'Nærmeste filament'),
    ('en', 'filament'): ('Studio with “Filament: all types”: the colour and the nearest filament, Atomic Filament Too Good to be Blue (PLA)', 'Nearest filament'),
    ('nb', 'del-app'): ('En delt palett åpnet i Kolorist: forhåndsvisning med farger og gradient, og «Legg til i paletter»', 'Mottatt i appen'),
    ('en', 'del-app'): ('A shared palette opened in Kolorist: preview with colours and gradient, and “Add to palettes”', 'Received in the app'),
    ('nb', 'del-web'): ('En delt palett i nettleseren på kolorist.no: fargene med hex, OKLCH, CIELab og Munsell', 'I nettleseren'),
    ('en', 'del-web'): ('A shared palette in the browser at kolorist.no: the colours with hex, OKLCH, CIELab and Munsell', 'In the browser'),
    ('nb', 'del-web-filament'): ('En delt filamentpalett i nettleseren på iPad, med lenke til hver prøve hos FilamentColors.xyz', 'Filament i nettleseren'),
    ('en', 'del-web-filament'): ('A shared filament palette in the browser on iPad, with a link to each sample at FilamentColors.xyz', 'Filament in the browser'),
})
# Bilder med annen sti eller størrelse enn iPhone-skjermbildene.
NYE_STIER = {'del-web-filament': ('ipad/skjermbilde-del-web-filament.png', 1032, 1376)}
NYE_ALT = {
    ('nb', 'lys'): 'Lys under Vurdering: fargen på skjermen og i stua om kvelden, og under flere betraktningsforhold med fargeskiftet for hvert',
    ('en', 'lys'): 'Light under Assess: the colour on screen and in the living room in the evening, and in more viewing conditions with the colour shift for each',
}


def iphonebilde(s, navn):
    lang = 'en' if '<html lang="en">' in s else 'nb'
    if (lang, navn) in NYE_BILDER:
        alt, tekst = NYE_BILDER[(lang, navn)]
        sti, b, h = NYE_STIER.get(navn, (f'skjermbilde-{navn}.png', 1284, 2778))
        src = f'assets/{sti}?v=8' if lang == 'nb' else f'../assets/en/{sti}?v=8'
        return f'<img src="{src}" alt="{alt}" width="{b}" height="{h}" loading="lazy">', tekst
    m = re.search(r'(<img src="[^"]*assets/(?:en/)?skjermbilde-' + navn + r'\.png[^"]*"[^>]*>)\s*<figcaption>(.*?)</figcaption>', s)
    img = m.group(1)
    if (lang, navn) in NYE_ALT:
        img = re.sub(r'alt="[^"]*"', f'alt="{NYE_ALT[(lang, navn)]}"', img).replace('?v=5', '?v=7')
    return img, m.group(2)


def seksjon(s, id_):
    return re.search(r'<section class="seksjon[^"]*" aria-labelledby="' + id_ + r'">(.*?)</section>', s, re.S).group(1)


def rykk(html, n):
    """Rykker inn alle linjer med n mellomrom (etter å ha fjernet felles innrykk)."""
    linjer = html.strip('\n').split('\n')
    minst = min((len(l) - len(l.lstrip()) for l in linjer[1:] if l.strip()), default=0)
    ut = [linjer[0].strip()] + [l[minst:] if l.strip() else '' for l in linjer[1:]]
    return '\n'.join(' ' * n + l if l else '' for l in ut)


def skjermbilder(s, navn, ekstra=''):
    """Bildestripe. Et navn på formen «kommer:Bildetekst» gir en plassholder («Skjermskudd kommer»)."""
    lis = []
    for n in navn:
        if n.startswith('kommer:'):
            kommer = 'Screenshot coming' if '<html lang="en">' in s else 'Skjermskudd kommer'
            lis.append(f'''        <li>
          <figure class="skjermbilde">
            <div class="ramme">{kommer}</div>
            <figcaption>{n[7:]}</figcaption>
          </figure>
        </li>''')
            continue
        img, tekst = iphonebilde(s, n)
        lis.append(f'''        <li>
          <figure class="skjermbilde">
            {img}
            <figcaption>{tekst}</figcaption>
          </figure>
        </li>''')
    return f'<ul class="skjermbilder{ekstra}" tabindex="0" aria-label="{{}}">\n' + '\n'.join(lis) + '\n      </ul>'


# ---------- Startsiden ----------

def startside(lang):
    s = kilde[lang]
    t = T[lang]
    N = f'<span class="nytt">{t["nytt"]}</span>'
    helt = re.search(r'(    <section class="helt".*?</section>)', s, re.S).group(1)
    if lang == 'nb':
        ingress = 'Fargeverktøy for design og arkitektur – på iPhone, iPad og Mac.'
        nyhet = f'<p class="nyhet">{N} <a href="design.html">Kontrastsjekk etter WCAG, APCA eller LRV, monokromatiske paletter, og farger og gradienter du kopierer rett inn i designprogrammene</a></p>'
        tekster = dict(
            kort='Kort fortalt',
            poeng=[('Farger slik øyet ser dem', 'Paletter, toner og overganger i like opplevde steg – i OKLCH, Munsell og alle fargerom og ICC-profiler.'),
                   ('Kontrast og fargesyn', 'Kontrast for tekst og flater etter WCAG, APCA og LRV, og farger slik de ser ut med fargesynsavvik.'),
                   ('Farger i ulikt lys', 'Simuler farger under andre betraktningsforhold, og kompenser plukkede farger for lyset de ble fotografert i – med gråkort eller referansekort.'),
                   ('Én app – én eller flere enheter', 'Samme app på iPhone, iPad og Mac. Bruk den på enheten du har eller på flere – alt synkroniseres via iCloud. <a href="plattformer.html">Se forskjellene</a>')],
            fagfelt='To fagfelt',
            dører=[('design.html', 'Design', 'Paletter, toneskalaer og gradienter for skjerm og trykk – rett inn i designverktøyene.', 'Kolorist for design', 'harmoni'),
                   ('arkitektur.html', 'Arkitektur', 'Hent farger fra rommet, angi dem i Munsell, se dem under andre betraktningsforhold og kontroller kontrasten mellom flater.', 'Kolorist for arkitektur og interiør', 'arkitektur-lys')],
            skjermbilder='Skjermbilder', rull='Skjermbilder – rull sidelengs',
            alle='Se alle funksjoner', alle_href='funksjoner.html',
            tillit='<strong>Alt skjer på enheten.</strong> Ingen konto, ingen bruksanalyse og ingen sporing. Palettene synkroniseres via din egen iCloud, og hver del av appen viser metodene den bygger på.',
            tillit_lenker='<a href="privacy.html">Personvern</a> · <a href="methods.html">Metoder og kilder</a>',
            tittel='Kolorist – farger for design og arkitektur',
            beskrivelse='Kolorist er et fargeverktøy for design og arkitektur på iPhone, iPad og Mac: farger i like opplevde steg, kontrastsjekk, simulering av fargesynsavvik og farger sett i lyset der de skal brukes.',
        )
    else:
        ingress = 'A colour tool for design and architecture – on iPhone, iPad and Mac.'
        nyhet = f'<p class="nyhet">{N} <a href="design.html">A contrast check by WCAG, APCA or LRV, monochromatic palettes, and colours and gradients you copy straight into your design apps</a></p>'
        tekster = dict(
            kort='In short',
            poeng=[('Colours as the eye sees them', 'Palettes, tones and gradients in perceptually equal steps – in OKLCH, Munsell and every colour space and ICC profile.'),
                   ('Contrast and colour vision', 'Contrast for text and surfaces by WCAG, APCA and LRV, and colours as they appear with colour vision deficiencies.'),
                   ('Colours in different light', 'Simulate colours in other viewing conditions, and compensate picked colours for the light they were photographed in – with a grey card or reference card.'),
                   ('One app – one or more devices', 'The same app on iPhone, iPad and Mac. Use it on the device you have or on several – everything syncs through iCloud. <a href="platforms.html">See the differences</a>')],
            fagfelt='Two fields',
            dører=[('design.html', 'Design', 'Palettes, tone scales and gradients for screen and print – straight into your design tools.', 'Kolorist for design', 'harmoni'),
                   ('architecture.html', 'Architecture', 'Take colours from the room, specify them in Munsell, see them in other viewing conditions and check the contrast between surfaces.', 'Kolorist for architecture and interiors', 'arkitektur-lys')],
            skjermbilder='Screenshots', rull='Screenshots – scroll sideways',
            alle='See all features', alle_href='features.html',
            tillit='<strong>Everything happens on device.</strong> No account, no analytics and no tracking. Palettes sync through your own iCloud, and every part of the app shows the methods it is based on.',
            tillit_lenker='<a href="privacy.html">Privacy</a> · <a href="methods.html">Methods and sources</a>',
            tittel='Kolorist – colour for design and architecture',
            beskrivelse='Kolorist is a colour tool for design and architecture on iPhone, iPad and Mac: colours in perceptually equal steps, contrast and colour vision checks, and colours seen in the light where they will be used.',
        )
    helt = re.sub(r'<p class="ingress">.*?</p>', f'<p class="ingress">{ingress}</p>', helt, flags=re.S)
    helt = re.sub(r'<p class="nyhet">.*?</p>', nyhet, helt, flags=re.S)

    poeng = '\n'.join(f'''        <li>
          <h3>{tt}</h3>
          <p>{tx}</p>
        </li>''' for tt, tx in tekster['poeng'])
    dører = []
    for href, tt, tx, videre, b in tekster['dører']:
        img, _ = iphonebilde(s, b)
        img = re.sub(r'alt="[^"]*"', 'alt=""', img)
        dører.append(f'''        <article class="dor">
          <div>
            <h3><a href="{href}">{tt}</a></h3>
            <p>{tx}</p>
            <p class="videre" aria-hidden="true">{videre} →</p>
          </div>
          {img}
        </article>''')
    # Plassholder: kontrastsjekken har fått ny utforming i 1.3 (stor flate, valg av WCAG, APCA eller LRV).
    kontrast = 'kommer:' + ('Kontrast: WCAG, APCA eller LRV' if lang == 'nb' else 'Contrast: WCAG, APCA or LRV')
    bilder = skjermbilder(s, ['studio', 'overgang', kontrast], ' tre').format(tekster['rull'])
    innhold = f'''{helt}

    <section class="seksjon" aria-labelledby="kort-fortalt">
      <h2 id="kort-fortalt">{tekster['kort']}</h2>
      <ul class="poeng">
{poeng}
      </ul>
    </section>

    <section class="seksjon" aria-labelledby="fagfelt">
      <h2 id="fagfelt">{tekster['fagfelt']}</h2>
      <div class="dorer">
{chr(10).join(dører)}
      </div>
    </section>

    <section class="seksjon" aria-labelledby="skjermbilder">
      <h2 id="skjermbilder">{tekster['skjermbilder']}</h2>
      {bilder}
      <p><a href="{tekster['alle_href']}">{tekster['alle']} →</a></p>
    </section>

    <section class="seksjon" aria-label="{'Personvern' if lang == 'nb' else 'Privacy'}">
      <div class="boks tillit">
        <p>{tekster['tillit']}</p>
        <p>{tekster['tillit_lenker']}</p>
      </div>
    </section>
'''
    return side(lang, 'index.html', tekster['tittel'], tekster['beskrivelse'], innhold)


# ---------- Fagsidene ----------

def nedlastknapp(s):
    return re.search(r'<a class="knapp" href="https://apps.apple.com.*?</a>', s, re.S).group(0)


def fagside(lang, fil, tittel, beskrivelse, overtittel, h1, ingress, steg, videre):
    s = kilde[lang]
    deler = []
    for st in steg:
        overskrift, tekst, punkter, bildenavn, lenke = st
        lis = '\n'.join(f'          <li>{p}</li>' for p in punkter)
        lenke_html = f'\n        <p><a href="{lenke[0]}">{lenke[1]} →</a></p>' if lenke else ''
        figur = ''
        if bildenavn and bildenavn.startswith('kommer:'):
            # Plassholder til skjermbildet er tatt.
            kommer = 'Screenshot coming' if lang == 'en' else 'Skjermskudd kommer'
            figur = f'''
      <figure class="skjermbilde">
        <div class="ramme">{kommer}</div>
        <figcaption>{bildenavn[7:]}</figcaption>
      </figure>'''
        elif bildenavn:
            img, tekst_b = iphonebilde(s, bildenavn)
            figur = f'''
      <figure class="skjermbilde">
        {img}
        <figcaption>{tekst_b}</figcaption>
      </figure>'''
        # Aksenter bort (é → e), men æ, ø og å beholdes.
        id_ = re.sub(r'[^a-zæøå0-9]+', '-', overskrift.lower().translate(str.maketrans('éèêáàóòôúü', 'eeeaaooouu'))).strip('-')
        deler.append(f'''    <section class="fagsteg{' med-bilde' if bildenavn else ''}" aria-labelledby="{id_}">
      <div>
        <h2 id="{id_}">{overskrift}</h2>
        <p class="lesetekst">{tekst}</p>
        <ul>
{lis}
        </ul>{lenke_html}
      </div>{figur}
    </section>''')
    lenker = '\n'.join(f'          <li><a href="{h}">{n}</a></li>' for h, n in videre[1])
    innhold = f'''    <header class="sidetopp">
      <p class="overtittel">{overtittel}</p>
      <h1>{h1}</h1>
      <p class="ingress">{ingress}</p>
    </header>

    <div class="fagsteg-liste">
{chr(10).join(deler)}
    </div>

    <section class="seksjon" aria-labelledby="les-videre">
      <div class="boks videre-boks">
        <h2 id="les-videre">{videre[0]}</h2>
        <ul>
{lenker}
        </ul>
        <div class="handlinger">
          {nedlastknapp(s)}
        </div>
      </div>
    </section>
'''
    return side(lang, fil, tittel, beskrivelse, innhold)


def design(lang):
    N = f' <span class="nytt">{T[lang]["nytt"]}</span>'
    if lang == 'nb':
        steg = [
            ('Finn fargene', 'Start fra et ord, et bilde eller en farge du allerede har.',
             ['Fra verdiord til palett med Apple Intelligence på enheten, forankret i en kunnskapsbase med over hundre fargebegreper',
              'Beskriv en farge – «dyp havblå», «støvete rosa» – og se den med en gang',
              'Harmonier på fargesirkler i OKLCH, CIE LCH, Munsell, Hering, HSL eller RYB – også triade, kvadrat og analog med komplementær aksent' + N12,
              'Goethes fargesirkel fra Farbenlehre (1810), med purpur, oransje, gul, grønn, blå og fiolett' + N,
              'Monokromatiske paletter: én kulør i toner du former fritt i lyshet og metning' + N,
              'Naturlig lyshetsrekkefølge: gule farger lysere og blå mørkere, som i naturen – eller omvendt for bevisst spenning' + N12,
              'Plukk farger med kameraet eller fra bilder rett fra fargefeltene – og fra hele skjermen på Mac' + N], 'monokrom', None),
            ('Bygg fargesystemet', 'Toner og overganger i like perseptuelle steg, så trinnene oppleves jevne.',
             ['Toneskalaer fra 50 til 950',
              'Lysere og mørkere toner i like eller avtagende steg, med verdier i valgt fargemodell' + N12,
              'Overganger i OKLab, med lysere og mørkere rader',
              'Dra på lyshetsstigen for å gjøre hele rekken lysere eller mørkere' + N12,
              'CSS-gradienter i oklab med sRGB-reserve – lineær, radiell eller konisk'], 'overgang', None),
            ('Kontroller', 'Kontroller kontrast og lesbarhet, også med fargesynsavvik.',
             ['WCAG 2.2-kontrast: AA og AAA, stor tekst og grafikk',
              'Kontrastsjekk etter WCAG 2.2, APCA eller LRV: øverst står tallet og det strengeste kravet fargen ikke klarer (for WCAG: AA-kravene), og tekst og bakgrunn velger du rett i fargeflaten' + N,
              '«Rett opp» endrer lysheten til fargen består',
              'Skriftkontrast for hele paletter, rett i palettvisningen' + N12,
              'Tekst på fargeflater i sort eller hvit etter opplevd lesbarhet (APCA), også på mellomtoner' + N,
              'Lesekontrast etter APCA (Lc), med hva kontrasten holder til: brødtekst, overskrifter eller grafikk' + N,
              'Paletter slik de oppleves med fargesynsavvik – og hvilke farger som blir vanskelige å skille'], 'skriftkontrast', None),
            ('Skjerm, trykk og 3D-print', 'Display P3 side om side med trykkprofiler, egne ICC-profiler og fargekart – og filamentfarger for 3D-print.',
             ['Display P3 side om side med sRGB, Adobe RGB, CMYK eller en hvilken som helst ICC-profil',
              'Varsel når fargen er utenfor fargeområdet – og begrens farger til en profil om du vil',
              'Rene CMYK-verdier: grått innslag flyttes til sort, med færrest mulig trykkfarger',
              'Kildefargerom for CMYK og RGB: angi verdiene i profilen de skal brukes i' + N,
              'CMYK i prosent; RGB som 0–255 i sRGB (de samme tallene som i hex) og 0–1 i andre fargerom' + N,
              'Betraktningsforhold for visningen: D50 (ICC-referanse), D65 eller andre – og papirhvitt med absolutt kolorimetrisk gjengivelse' + N,
              'Fargekart med navngitte toner: arbeid innenfor dem, med tonenavn vist',
              'Vurder trykk og bilder under standardlys for grafisk vurdering (ISO 3664)' + N12,
              'Filamentfarger for 3D-print: over 2 200 farger fra 150 produsenter, de fleste målt med kolorimeter – finn nærmeste filament, med lenke til prøven (<a href="filament.html">les mer</a>)' + N12],
             'studio', ('lys.html', 'Les om lys og fargemåling')),
            ('Levér', 'Eksporter og kopier farger til andre programmer, i formatet de ble laget i.',
             ['Eksport til ASE, ACO, design tokens (DTCG-JSON), CSS, SwiftUI, GPL, SVG-fargeprøver og hex-lister',
              'Farger eksporteres i formatet de er laget i – for eksempel CMYK som CMYK',
              'Kopier farger og gradienter rett inn i design-, layout-, kontor- og presentasjonsprogrammer – som figurer og redigerbare gradienter, ikke bilder' + N,
              'Velg selv hvilke programmer «Kopier til» viser, og i hvilken rekkefølge' + N,
              'Dra fargeprøver rett inn i andre programmer på Mac – og farger inn i Kolorist',
              'Skriv ut paletter som A4-PDF med fargeflater i CIELab, navn og verdier – også harmonier, overganger og palettgrupper' + N,
              'Lagre som: paletter og farger i flere formater samtidig – i en mappe du velger, også i en skytjeneste – eller del filene direkte' + N12,
              'Del farger, paletter, gradienter og harmonier som lenke – mottakere uten appen ser fargene i nettleseren' + N12,
              'Siri og Snarveier: lag paletter og overganger, konverter farger og sjekk kontrast'], 'palettgrupper', None),
        ]
        return fagside('nb', 'design.html', 'Kolorist for design – paletter, toner, kontroll og eksport',
                       'Fargeverktøy for design: paletter og harmonier, toneskalaer og gradienter i like opplevde steg, kontrastsjekk, simulering av fargesynsavvik, ICC og trykk, og eksport til designverktøyene.',
                       'Kolorist for', 'Design',
                       'Fra første idé til ferdige fargefiler: paletter, toneskalaer og gradienter i like opplevde steg. Kontroller kontrasten, se fargene slik de ser ut med fargesynsavvik, og kopier dem rett inn i verktøyene du bruker.',
                       steg, ('Les videre', [('lys.html', 'Lys og fargemåling'), ('funksjoner.html', 'Alle funksjoner'), ('arkitektur.html', 'Kolorist for arkitektur og interiørarkitektur')]))
    steg = [
        ('Find the colours', 'Start from a word, a photo or a colour you already have.',
         ['From value words to a palette with Apple Intelligence on device, grounded in a knowledge base of more than a hundred colour concepts',
          'Describe a colour – “deep ocean blue”, “dusty pink” – and see it right away',
          'Harmonies on an OKLCH, CIE LCH, Munsell, Hering, HSL or RYB colour wheel – including triad, square and analogous with a complementary accent' + N12,
          'Goethe’s colour wheel from his Theory of Colours (1810), with purple, orange, yellow, green, blue and violet' + N,
          'Monochromatic palettes: one hue in tones you shape freely in lightness and saturation' + N,
          'Natural lightness order: yellows lighter and blues darker, as in nature – or reversed for deliberate tension' + N12,
          'Pick colours with the camera or from photos right from the colour fields – and from anywhere on screen on the Mac' + N], 'monokrom', None),
        ('Build the colour system', 'Tones and gradients in perceptually equal steps, so the steps look even.',
         ['Tone scales from 50 to 950',
          'Lighter and darker tones in equal or easing steps, with values in the chosen colour model' + N12,
          'Gradients in OKLab, with lighter and darker rows',
          'Drag on the lightness ladder to make the whole row lighter or darker' + N12,
          'CSS gradients in oklab with an sRGB fallback – linear, radial or conic'], 'overgang', None),
        ('Check', 'Check contrast and legibility, including with colour vision deficiencies.',
         ['WCAG 2.2 contrast: AA and AAA, large text and graphics',
          'Contrast check by WCAG 2.2, APCA or LRV: the figure and the strictest requirement the colour does not meet are shown at the top (for WCAG: the AA requirements), and you pick text and background right in the colour field' + N,
          'Auto-fix changes the lightness until the colour passes',
          'Text contrast for whole palettes, right in the palette view' + N12,
          'Text on colour fields in black or white by perceived legibility (APCA), mid-tones included' + N,
          'Reading contrast by APCA (Lc), with what the contrast is good for: body text, headlines or graphics' + N,
          'Palettes as they appear with colour vision deficiencies – and which colours become hard to tell apart'], 'skriftkontrast', None),
        ('Screen, print and 3D printing', 'Display P3 side by side with print profiles, your own ICC profiles and colour libraries – and filament colours for 3D printing.',
         ['Display P3 side by side with sRGB, Adobe RGB, CMYK or any ICC profile',
          'A warning when the colour is out of gamut – and limit colours to a profile if you like',
          'Clean CMYK values: grey components move to black, with as few inks as possible',
          'Source colour space for CMYK and RGB: enter the values in the profile they will be used in' + N,
          'CMYK in percent, and RGB as 0–255 in sRGB – the same numbers as in hex – and 0–1 in other colour spaces' + N,
          'Viewing light: D50 (ICC standard), D65 or a viewing condition – and paper white with absolute colorimetric' + N,
          'Colour libraries with named tones: work within them, with tone names shown',
          'Judge print and images under standard viewing conditions for graphic arts (ISO 3664)' + N12,
          'Filament colours for 3D printing: more than 2,200 colours from 150 manufacturers, most measured with a colorimeter – find the nearest filament, with a link to the sample (<a href="filament.html">read more</a>)' + N12],
         'studio', ('light.html', 'Read about light and colour measurement')),
        ('Deliver', 'Export and copy colours to other apps, in the format they were made in.',
         ['Export to ASE, ACO, design tokens (DTCG JSON), CSS, SwiftUI, GPL, SVG swatches and hex lists',
          'Colours are exported in the format they were made in – CMYK as CMYK, for example',
          'Copy colours and gradients straight into design, layout, office and presentation apps – as shapes and editable gradients, not images' + N,
          'Choose which apps “Copy to” shows, and in what order' + N,
          'Drag swatches straight into other apps on the Mac – and colours into Kolorist',
          'Print palettes as an A4 PDF with swatches in CIELab, names and values – harmonies, gradients and palette groups too' + N,
          'Save as: palettes and colours in several formats at once – in a folder you choose, including a cloud service – or share the files directly' + N12,
          'Share colours, palettes, gradients and harmonies as a link – recipients without the app see the colours in their browser' + N12,
          'Siri and Shortcuts: make palettes and gradients, convert colours and check contrast'], 'palettgrupper', None),
    ]
    return fagside('en', 'design.html', 'Kolorist for design – palettes, tones, checks and export',
                   'A colour tool for design: palettes and harmonies, tone scales and gradients in perceptually equal steps, contrast checks, simulation of colour vision deficiencies, ICC and print, and export to your design tools.',
                   'Kolorist for', 'Design',
                   'From the first idea to finished colour files: palettes, tone scales and gradients in perceptually equal steps. Check the contrast, see the colours as they appear with colour vision deficiencies, and copy them straight into the tools you use.',
                   steg, ('Read on', [('light.html', 'Light and colour measurement'), ('features.html', 'All features'), ('architecture.html', 'Kolorist for architecture and interior architecture')]))


def arkitektur(lang):
    N = f' <span class="nytt">{T[lang]["nytt"]}</span>'
    if lang == 'nb':
        steg = [
            ('Hent farger fra rom og materialer', 'Telefonen blir et enkelt måleverktøy for farge.',
             ['Kamera med zoom, makrofokus og lykt',
              'Kompenser plukkede farger for lyset med gråkort eller referansekort – også i bilder (beta)' + N12,
              'Mål lyset der du står og lagre det som betraktningsforhold' + N12,
              'Dominerende farger i bilder'], None, None),
            ('Spesifiser', 'Angi farger med Munsell-notasjon, CIELab og fargekart.',
             ['Munsell i trinnene fra Munsell-boka – kulør 2,5, valør 1 og kroma 2 – med Munsell-notasjon' + N12,
              'Harmonier på Munsells fargesirkel, med ekte Munsell-farger',
              'Fargekart med navngitte toner: importer dine egne (ASE, ACO, ACB) og finn nærmeste tone',
              'CIELab (D50) og fargeforskjell med ΔE2000'], 'munsell', None),
            ('Se fargene i lyset', 'Simuler farger og hele paletter under betraktningsforholdene der de skal brukes.',
             ['Betraktningsforhold for stua om kvelden, kontoret og butikken – eller lyset du har målt på stedet' + N12,
              'Standard betraktningsforhold for arbeidsplasser og skoler (NS-EN 12464-1) og museer (CIE 157)' + N12,
              'Fargen på skjermen og i lyset side om side, og under flere betraktningsforhold med fargeskiftet for hvert' + N12,
              'Hele paletter i lys, rett i palettvisningen' + N12,
              'Farger som skifter karakter, og fargepar som blir vanskelige å skille i svakt lys eller under lysrør og LED' + N12],
             'arkitektur-lys', ('lys.html', 'Les om lys og fargemåling')),
            ('Universell utforming', 'Kontrast mellom flater – dører, vegger, gulv og skilt – ikke bare tekst.',
             ['To flater side om side med lysrefleksjonsverdi (LRV) og kontrasten mellom dem' + N,
              'Velg beregningsmetode: LRV-forskjell (BS 8300), Weber (TEK17, NS 11001) eller Michelson (ISO 21542) – hver med sine krav' + N,
              'Plukk begge flatene med kameraet – uten gråkort eller referansekort merkes LRV som veiledende' + N,
              'LRV og luminanskontrast i valgt lys – også lysrør og LED' + N12,
              'WCAG-kontrast for skilt og tekst',
              'Farger og paletter slik de oppleves med fargesynsavvik – og et kamera med fargesynsfilter for omgivelsene'],
             'kommer:Kontrast mellom flater: to flater side om side med LRV og valgt metode', None),
            ('Mål og dokumenter', 'Dokumenter lysforhold og fargevalg, og del dem.',
             ['Mål fargetemperatur, belysningsstyrke (lux) og anslått fargegjengivelse med iPhone eller iPad' + N12,
              'Sammenlign med anbefalte nivåer, for eksempel 500 lx på en arbeidsplass',
              'Lagre målt lys som betraktningsforhold, og se andre farger under det' + N12,
              'Skriv ut paletter som A4-PDF med fargeflater i CIELab, navn og verdier – også harmonier, overganger og palettgrupper' + N,
              'Lagre som: paletter og farger i flere formater samtidig – i en mappe du velger, også i en skytjeneste – eller del filene direkte' + N12,
              'Del farger, paletter, gradienter og harmonier som lenke – mottakere uten appen ser fargene i nettleseren' + N12,
              'Paletter og betraktningsforhold synkroniseres til iPad og Mac via iCloud'], None, None),
        ]
        return fagside('nb', 'arkitektur.html', 'Kolorist for arkitektur og interiørarkitektur',
                       'Fargeverktøy for arkitektur og interiørarkitektur: plukk farger fra rom og materialer, spesifiser i Munsell, se farger i lyset der de skal brukes, og kontroller kontrasten mellom flater (LRV) for universell utforming.',
                       'Kolorist for', 'Arkitektur og interiørarkitektur',
                       'Farger for rom og bygg: hent dem fra materialer og omgivelser, spesifiser dem presist, se dem i lyset der de skal brukes, og kontroller kontrasten for universell utforming.',
                       steg, ('Les videre', [('lys.html', 'Lys og fargemåling'), ('funksjoner.html', 'Alle funksjoner'), ('design.html', 'Kolorist for design')]))
    steg = [
        ('Take colours from rooms and materials', 'Your phone becomes a simple colour measuring tool.',
         ['Camera with zoom, macro focus and torch',
          'Compensate picked colours for the light with a grey card or reference card – in photos too (beta)' + N12,
          'Measure the light where you are and save it as a viewing condition' + N12,
          'Dominant colours in photos'], None, None),
        ('Specify', 'Specify colours with Munsell notation, CIELab and colour libraries.',
         ['Munsell in the steps of the Munsell book – hue 2.5, value 1 and chroma 2 – with Munsell notation' + N12,
          'Harmonies on the Munsell colour wheel, with real Munsell colours',
          'Colour libraries with named tones: import your own (ASE, ACO, ACB) and find the nearest tone',
          'CIELab (D50) and colour difference with ΔE2000'], 'munsell', None),
        ('See the colours in the light', 'Simulate colours and whole palettes in the viewing conditions where they will be used.',
         ['Viewing conditions for the living room in the evening, the office and the shop – or the light you measured on site' + N12,
          'Standard viewing conditions for workplaces and schools (EN 12464-1) and museums (CIE 157)' + N12,
          'The colour on screen and in the light side by side, and in several viewing conditions with the colour shift for each' + N12,
          'Whole palettes in light, right in the palette view' + N12,
          'Colours that change character, and colour pairs that become hard to tell apart in dim light or under fluorescent and LED lighting' + N12],
         'arkitektur-lys', ('light.html', 'Read about light and colour measurement')),
        ('Universal design', 'Contrast between surfaces – doors, walls, floors and signs – not just text.',
         ['Two surfaces side by side with light reflectance value (LRV) and the contrast between them' + N,
          'Choose the method: LRV difference (BS 8300), Weber (Norwegian TEK17, NS 11001) or Michelson (ISO 21542) – each with its own requirements' + N,
          'Pick both surfaces with the camera – without a grey card or reference card the LRV is marked as indicative' + N,
          'LRV and luminance contrast in the chosen light – including fluorescent and LED' + N12,
          'WCAG contrast for signs and text',
          'Colours and palettes as they appear with colour vision deficiencies – and a camera with a colour vision filter for your surroundings'],
         'kommer:Contrast between surfaces: two surfaces side by side with LRV and the chosen method', None),
        ('Measure and document', 'Document lighting conditions and colour choices, and share them.',
         ['Measure colour temperature, illuminance (lux) and estimated colour rendering with iPhone or iPad' + N12,
          'Compare with recommended levels, such as 500 lx at a workplace',
          'Save measured light as a viewing condition, and see other colours under it' + N12,
          'Print palettes as an A4 PDF with swatches in CIELab, names and values – harmonies, gradients and palette groups too' + N,
          'Save as: palettes and colours in several formats at once – in a folder you choose, including a cloud service – or share the files directly' + N12,
          'Share colours, palettes, gradients and harmonies as a link – recipients without the app see the colours in their browser' + N12,
          'Palettes and viewing conditions sync to iPad and Mac through iCloud'], None, None),
    ]
    return fagside('en', 'architecture.html', 'Kolorist for architecture and interior architecture',
                   'A colour tool for architecture and interior architecture: pick colours from rooms and materials, specify them in Munsell, see colours in the light where they will be used, and check LRV and contrast for universal design.',
                   'Kolorist for', 'Architecture and interior architecture',
                   'Colours for rooms and buildings: take them from materials and surroundings, specify them precisely, see them in the light where they will be used, and check the contrast for universal design.',
                   steg, ('Read on', [('light.html', 'Light and colour measurement'), ('features.html', 'All features'), ('design.html', 'Kolorist for design')]))


# ---------- Lys og fargemåling ----------

def lysside(lang):
    s = kilde[lang]
    sek = seksjon(s, 'lys')
    sek = re.sub(r'\s*<p class="overtittel">.*?</p>\s*<h2 id="lys">(.*?)</h2>', '', sek, flags=re.S)
    h1 = 'Lys og fargemåling' if lang == 'nb' else 'Light and colour measurement'
    over = re.search(r'<p class="overtittel">.*?</p>', seksjon(s, 'lys'), re.S).group(0)
    fil = 'lys.html' if lang == 'nb' else 'light.html'
    videre = ([('arkitektur.html', 'Kolorist for arkitektur og interiørarkitektur'), ('design.html', 'Kolorist for design'), ('funksjoner.html', 'Alle funksjoner')]
              if lang == 'nb' else
              [('architecture.html', 'Kolorist for architecture and interior architecture'), ('design.html', 'Kolorist for design'), ('features.html', 'All features')])
    lenker = '\n'.join(f'          <li><a href="{h}">{n}</a></li>' for h, n in videre)
    bilder = skjermbilder(s, ['arkitektur-lys', 'palett-lys'], ' tre').format(
        'Skjermbilder – rull sidelengs' if lang == 'nb' else 'Screenshots – scroll sideways')
    innhold = f'''    <header class="sidetopp">
      {over}
      <h1>{h1}</h1>
    </header>
{rykk(sek, 4)}

    <section class="seksjon" aria-label="{'Skjermbilder' if lang == 'nb' else 'Screenshots'}">
      {bilder}
    </section>

    <section class="seksjon" aria-labelledby="les-videre">
      <div class="boks videre-boks">
        <h2 id="les-videre">{'Les videre' if lang == 'nb' else 'Read on'}</h2>
        <ul>
{lenker}
        </ul>
      </div>
    </section>
'''
    tittel = 'Lys og fargemåling – Kolorist' if lang == 'nb' else 'Light and colour measurement – Kolorist'
    beskr = ('Se farger og paletter i lyset der de skal brukes, kompenser plukkede farger for lyset, og mål farge og lys med gråkort og referansekort.'
             if lang == 'nb' else
             'See colours and palettes in the light where they will be used, compensate picked colours for the light, and measure colour and light with grey cards and reference cards.')
    return side(lang, fil, tittel, beskr, innhold)


# ---------- Alle funksjoner ----------

# Tilgjengelighet-kortet: 0 WCAG, 1 APCA på fargeflater, 2 APCA-lesekontrast, 3 valg av kontrastsjekk, 4 Rett opp,
# 5 skriftkontrast i paletter, 6 vurderinger viser grunnlaget, 7 LRV og metoder, 8 LRV i lys, 9 veiledende LRV fra kamera,
# 10 paletter i ulike lys, 11 ΔE2000, 12 fargesyn, 13 utbredelse, 14 kamera.
TILG_TEKST = (0, 1, 2, 3, 4, 5, 6, 11)
TILG_FLATER = (7, 8, 9, 10)
TILG_FARGESYN = (12, 13, 14)


def funksjoner(lang):
    s = kilde[lang]
    k = kort(s)
    t = T[lang]
    N = f'<span class="nytt">{t["nytt"]}</span>'
    nb = lang == 'nb'
    tilg = lier(k['Tilgjengelighet' if nb else 'Accessibility'])
    # Punktene i Tilgjengelighet-kortet på forsiden, fordelt på gruppene. Settes et punkt inn i kortet, må tallene følge med.
    assert len(tilg) == 15, f'Tilgjengelighet-kortet har {len(tilg)} punkter – oppdater TILG_* i funksjoner()'
    lysliste = (['Se farger og hele paletter under egne og standardiserte betraktningsforhold – paletter rett i palettvisningen',
                 'Kompenser plukkede farger for lyset med gråkort eller referansekort – også i bilder (beta)',
                 'Mål lyset med kameraet og lagre det som betraktningsforhold – lysstyrken anslås, eller måles med et kort',
                 'Mål fargetemperatur, belysningsstyrke og anslått fargegjengivelse',
                 'Importer referanseverdiene for ditt eget kort'] if nb else
                ['See colours and whole palettes in viewing conditions and standard viewing conditions – palettes right in the palette view',
                 'Compensate picked colours for the light with a grey card or reference card – in photos too (beta)',
                 'Measure the light with the camera and save it as a viewing condition – the illuminance is estimated, or measured with a card',
                 'Measure colour temperature, illuminance and estimated colour rendering',
                 'Import the reference values for your own card'])
    lysdel = ('<p>Simuler farger og paletter under andre betraktningsforhold, og kompenser plukkede farger for lyset de ble fotografert i. Et gråkort eller et referansekort gjør telefonen til et enkelt måleverktøy for farge og lys.</p>'
              if nb else
              '<p>Simulate colours and palettes in other viewing conditions, and compensate picked colours for the light they were photographed in. A grey card or a reference card turns your phone into a simple measuring tool for colour and light.</p>')
    lysdel += '\n<ul>\n' + '\n'.join(f'  <li>{p}</li>' for p in lysliste) + '\n</ul>\n'
    lysdel += f'<p><a href="{"lys.html" if nb else "light.html"}">{"Les alt om lys og fargemåling" if nb else "Read all about light and colour measurement"} →</a></p>'

    def ul(lis):
        return '<ul>\n' + '\n'.join('  ' + li.strip() for li in lis) + '\n</ul>'

    plukk = k['Plukk farger' if nb else 'Pick colours'].replace('href="#lys"', f'href="{"lys.html" if nb else "light.html"}"')
    plattform_tekst = re.search(r'<p class="lesetekst">(.*?)</p>', seksjon(s, 'funksjoner'), re.S).group(1).strip()
    mac = re.search(r'(<h3 class="skjermbilder-tittel">Mac</h3>.*?</div>)\s*$', seksjon(s, 'skjermbilder'), re.S).group(1)
    kontrast = 'kommer:' + ('Kontrast: WCAG, APCA eller LRV' if nb else 'Contrast: WCAG, APCA or LRV')
    iphone = skjermbilder(s, ['studio', 'harmoni', 'overgang', kontrast, 'fargesyn', 'lys']).format(
        'Skjermbilder – rull sidelengs' if nb else 'Screenshots – scroll sideways')

    if nb:
        grupper = [
            ('fargerom', 'Farger og fargerom', 'Fargerom', None,
             [('Alle fargerom', k['Alle fargerom']), ('ICC-profiler og fargebiblioteker', k['ICC-profiler og fargebiblioteker']),
              ('Filamentfarger for 3D-print', ul([f'<li>Over 2 200 filamentfarger fra 150 produsenter, i ett bibliotek per materiale: PLA, PETG, ABS og ASA, TPU og TPE og andre {N12}</li>',
                                                  '<li>De fleste målt med kolorimeter på utskrevne prøver; resten anslått fra foto og merket slik</li>',
                                                  '<li>Finn nærmeste filament til en farge, eller lås paletter og harmonier til filamenter som finnes</li>',
                                                  '<li>Hver farge lenker til prøven hos <a href="https://filamentcolors.xyz/">FilamentColors.xyz</a> (CC BY 4.0) – <a href="methods.html#filamentfarger">om dataene</a></li>',
                                                  '<li><a href="filament.html">Les mer om 3D-print og filament</a></li>']))]),
            ('toner', 'Toner, harmonier og overganger', 'Toner og overganger', None,
             [('Toner og harmonier', k['Toner og harmonier']), ('Overganger', k['Overganger'])]),
            ('hent', 'Hent farger', 'Hent farger', None,
             [('Plukk farger', plukk), ('Apple Intelligence på enheten', k['Apple Intelligence på enheten'])]),
            ('kontrast', 'Kontrast og fargesyn', 'Kontrast og fargesyn', None,
             [('Tekst og grafikk (WCAG 2.2 og APCA)', ul([tilg[i] for i in TILG_TEKST])),
              ('Flater og bygg (LRV)', ul([tilg[i] for i in TILG_FLATER])),
              ('Fargesyn', ul([tilg[i] for i in TILG_FARGESYN]))]),
            ('lys', 'Lys og fargemåling', 'Lys', lysdel, []),
            ('levere', 'Paletter, eksport og deling', 'Paletter og eksport', None,
             [('Paletter og iCloud', k['Paletter og iCloud']), ('Eksport', k['Eksport']),
              ('Lagre som', ul([f'<li>Velg formatene etter hvor filene skal brukes – designprogrammer, nett, apputvikling og andre – og lagre flere samtidig {N12}</li>',
                                '<li>Lagre i en mappe du velger, også i skytjenester – eller del filene med e-post, meldinger og deling i nærheten</li>',
                                '<li>For paletter og enkeltfarger</li>'])),
              ('Delingslenker', ul([f'<li>Del enkeltfarger, paletter, gradienter og harmonier som lenke {N12}</li>',
                                    '<li>Med Kolorist åpnes lenken i appen, og du velger selv om noe skal lagres</li>',
                                    '<li>Uten appen – også på PC – vises fargene i nettleseren, med hex, OKLCH, CIELab og Munsell</li>',
                                    '<li>Fargene ligger i selve lenken; ingenting lagres eller sendes via nettstedet</li>',
                                    '<li>Tonenavn fra fargekart du har importert, tas ikke med – bare fargeverdiene deles</li>',
                                    '<li><a href="https://kolorist.no/l#znZJLTsMwEIavYlliFxw_M-PuaEpZVLAoK4S6CCWUkL6UtIiq6nE4CRdjnAfKmo09Htuf5v9nzvyNj57PvKRVCmMSqaJrKaQ2XWCVShYR3xz5iCs5ZlqY2AjLI76lzOS0Z28fu-qVzl_hxdTc2Am_RD3RKatNAzI-cS0Rve6JINyYWUJaAR1ydqoPL-uf745opsktugERLEjf1uhtGxh0dlgjEE71FRZ1sWLvxWaTrzskTscmhQESPSgVEUhqMGHXCL4HauGeGAqM1Z_qx2zbC75NJmmKQ8FeIxJDaZANEw2agdw5c7GSwneoh-xYHyiuKC6Wy1GZ3qW79a563GfL_C7f5lWxTO-fZuFJeN-m6pL1yUOjmcUMkBbUtOircPFJ5SgZAUaoo2B4KDdF5wz1h46rpu8ZH0EnqjxuqmK7or91c0WD8a-5GM5B8GXAAaCeBVPAtbvXSg2NnjMQOsY_zlR7cpg4i1ByYxgNW9Bfnhrfgvx9ts4P4UCS1eUX">Åpne en delt eksempelpalett</a> – og se <a href="plattformer.html#del">hvordan deling fungerer</a></li>'])),
              ('Siri og Snarveier', k['Siri og Snarveier'])]),
            ('plattformer', 'iPhone, iPad og Mac', 'iPhone, iPad og Mac', f'<p class="lesetekst">{plattform_tekst}</p>\n<p><a href="plattformer.html">Se forskjellene, med skjermbilder fra hver plattform →</a></p>', []),
            ('metoder', 'Metodene', 'Metodene', k['Åpent om metodene'], []),
        ]
        tittel, h1 = 'Alle funksjoner – Kolorist', 'Alle funksjoner'
        intro = f'Alt Kolorist kan, samlet etter tema. Det som er nytt i versjon {VERSJON}, er merket med {N}'
        beskr = 'Alle funksjoner i Kolorist: fargerom og ICC, toner, harmonier og overganger, fargeplukking, kontrast og fargesyn, lys og fargemåling, paletter og eksport.'
        innholdsliste = 'Innhold på siden'
    else:
        grupper = [
            ('colour-spaces', 'Colours and colour spaces', 'Colour spaces', None,
             [('Every colour space', k['Every colour space']), ('ICC profiles and colour libraries', k['ICC profiles and colour libraries']),
              ('Filament colours for 3D printing', ul([f'<li>More than 2,200 filament colours from 150 manufacturers, in one library per material: PLA, PETG, ABS and ASA, TPU and TPE and others {N12}</li>',
                                                       '<li>Most measured with a colorimeter on printed samples; the rest estimated from photos and marked as such</li>',
                                                       '<li>Find the nearest filament to a colour, or lock palettes and harmonies to filaments that exist</li>',
                                                       '<li>Each colour links to the sample at <a href="https://filamentcolors.xyz/">FilamentColors.xyz</a> (CC BY 4.0) – <a href="methods.html#filamentfarger">about the data</a></li>',
                                                       '<li><a href="filament.html">Read more about 3D printing and filament</a></li>']))]),
            ('tones', 'Tones, harmonies and gradients', 'Tones and gradients', None,
             [('Tones and harmonies', k['Tones and harmonies']), ('Gradients', k['Gradients'])]),
            ('getting-colours', 'Getting colours', 'Getting colours', None,
             [('Pick colours', plukk), ('Apple Intelligence on device', k['Apple Intelligence on device'])]),
            ('contrast', 'Contrast and colour vision', 'Contrast and colour vision', None,
             [('Text and graphics (WCAG 2.2 and APCA)', ul([tilg[i] for i in TILG_TEKST])),
              ('Surfaces and buildings (LRV)', ul([tilg[i] for i in TILG_FLATER])),
              ('Colour vision', ul([tilg[i] for i in TILG_FARGESYN]))]),
            ('light', 'Light and colour measurement', 'Light', lysdel, []),
            ('deliver', 'Palettes, export and sharing', 'Palettes and export', None,
             [('Palettes and iCloud', k['Palettes and iCloud']), ('Export', k['Export']),
              ('Save as', ul([f'<li>Choose formats by where the files will be used – design apps, the web, app development and more – and save several at once {N12}</li>',
                              '<li>Save to a folder you choose, including cloud services – or share the files by email, messages and nearby sharing</li>',
                              '<li>For palettes and single colours</li>'])),
              ('Share links', ul([f'<li>Share single colours, palettes, gradients and harmonies as a link {N12}</li>',
                                  '<li>With Kolorist the link opens in the app, and you decide whether to save anything</li>',
                                  '<li>Without the app – on PCs too – the colours are shown in the browser, with hex, OKLCH, CIELab and Munsell</li>',
                                  '<li>The colours are in the link itself; nothing is stored or sent through the website</li>',
                                  '<li>Tone names from colour charts you have imported are left out – only the colour values are shared</li>',
                                  '<li><a href="https://kolorist.no/l#znZJLTsMwEIavYlliFxw_M-PuaEpZVLAoK4S6CCWUkL6UtIiq6nE4CRdjnAfKmo09Htuf5v9nzvyNj57PvKRVCmMSqaJrKaQ2XWCVShYR3xz5iCs5ZlqY2AjLI76lzOS0Z28fu-qVzl_hxdTc2Am_RD3RKatNAzI-cS0Rve6JINyYWUJaAR1ydqoPL-uf745opsktugERLEjf1uhtGxh0dlgjEE71FRZ1sWLvxWaTrzskTscmhQESPSgVEUhqMGHXCL4HauGeGAqM1Z_qx2zbC75NJmmKQ8FeIxJDaZANEw2agdw5c7GSwneoh-xYHyiuKC6Wy1GZ3qW79a563GfL_C7f5lWxTO-fZuFJeN-m6pL1yUOjmcUMkBbUtOircPFJ5SgZAUaoo2B4KDdF5wz1h46rpu8ZH0EnqjxuqmK7or91c0WD8a-5GM5B8GXAAaCeBVPAtbvXSg2NnjMQOsY_zlR7cpg4i1ByYxgNW9Bfnhrfgvx9ts4P4UCS1eUX">Open a shared example palette</a> – and see <a href="platforms.html#del">how sharing works</a></li>'])),
              ('Siri and Shortcuts', k['Siri and Shortcuts'])]),
            ('platforms', 'iPhone, iPad and Mac', 'iPhone, iPad and Mac', f'<p class="lesetekst">{plattform_tekst}</p>\n<p><a href="platforms.html">See the differences, with screenshots from each platform →</a></p>', []),
            ('methods', 'The methods', 'The methods', k['Open about methods'], []),
        ]
        tittel, h1 = 'All features – Kolorist', 'All features'
        intro = f'Everything Kolorist can do, grouped by theme. What’s new in version {VERSJON} is marked with {N}'
        beskr = 'All features in Kolorist: colour spaces and ICC, tones, harmonies and gradients, colour picking, contrast and colour vision, light and colour measurement, palettes and export.'
        innholdsliste = 'On this page'

    toc = '\n'.join(f'          <li><a href="#{g[0]}">{g[2]}</a></li>' for g in grupper)
    deler = []
    for id_, overskrift, _, tekst, under in grupper:
        innh = ''
        if tekst:
            innh += '\n' + rykk(tekst, 6)
        if under:
            blokker = '\n'.join(f'''        <div>
          <h3>{h}</h3>
{rykk(inner, 10)}
        </div>''' for h, inner in under)
            innh += f'\n      <div class="underpunkter">\n{blokker}\n      </div>'
        deler.append(f'''    <section class="funksjonsgruppe" id="{id_}" aria-labelledby="{id_}-tittel">
      <h2 id="{id_}-tittel">{overskrift}</h2>{innh}
    </section>''')
    innhold = f'''    <header class="sidetopp">
      <h1>{h1}</h1>
      <p class="dempet">{intro}</p>
      <nav class="innholdsliste" aria-label="{innholdsliste}">
        <ul>
{toc}
        </ul>
      </nav>
    </header>

{chr(10).join(deler)}
'''
    return side(lang, 'funksjoner.html' if nb else 'features.html', tittel, beskr, innhold)


# ---------- Plattformer ----------

def macbilde(s, navn):
    return re.search(r'<img src="[^"]*assets/(?:en/)?mac/skjermbilde-' + navn + r'\.png[^"]*"[^>]*>', s).group(0)


def plattformer(lang):
    s = kilde[lang]
    nb = lang == 'nb'
    t = T[lang]
    N = f' <span class="nytt">{t["nytt"]}</span>'
    ja = '<span aria-hidden="true">✓</span><span class="visuelt-skjult">' + ('Ja' if nb else 'Yes') + '</span>'
    nei = '<span aria-hidden="true">–</span><span class="visuelt-skjult">' + ('Nei' if nb else 'No') + '</span>'
    if nb:
        tittel = 'iPhone, iPad og Mac – Kolorist'
        beskr = 'Kolorist er én app for iPhone, iPad og Mac. Bruk én eller flere – palettene, betraktningsforholdene og profilene følger med via iCloud.'
        h1 = 'iPhone, iPad og Mac'
        ingress = 'Én app for iPhone, iPad og Mac. Bruk den på enheten du har – eller på flere, med palettene, betraktningsforholdene og profilene dine synkronisert via iCloud.'
        styrker_tittel = 'Hver enhet sin styrke'
        styrker = [('iPhone', 'Alltid med deg: plukk farger med kameraet, mål lyset og simuler farger under andre betraktningsforhold.'),
                   ('iPad', 'Mer plass: i liggende format ligger fargeflatene ved siden av verktøyene, og på store iPader er palettene for hånden.'),
                   ('Mac', 'Bredt vindu: pipette for hele skjermen og fargeprøver du drar rett inn i andre programmer.')]
        sammen_tittel = 'Sammen'
        sammen = ['Paletter, enkeltfarger og gradienter følger med mellom enhetene via din egen iCloud',
                  'ICC-profiler og fargekart ligger i appens mappe i iCloud Drive',
                  'Mål lyset med iPhone eller iPad – og se farger i det samme lyset på Mac' + N12,
                  'Bruk iPhone som kamera på Mac, med kompensasjon for lyset' + N12,
                  'Oppsettet av visningen følger med',
                  'Kolleger på PC: lagre paletter i formatene de bruker, i en mappe i skytjenesten dere deler' + N12,
                  'Delte lenker åpnes i appen på iPhone, iPad og Mac – og i nettleseren ellers, også på PC' + N12]
        side_tittel = 'Side om side'
        side_intro = 'Samme verktøy, tilpasset skjermen.'
        # None: skjermbildene er ikke tatt ennå (plassholder for hver plattform).
        visninger = [('studio', 'Studio'), ('harmoni', 'Harmoni'), ('overgang', 'Overgang'),
                     (None, 'Kontrast: WCAG, APCA eller LRV'), (None, 'Plukk farge fra et fargefelt'),
                     (None, 'Presentasjonsmodus')]
        tabell_tittel = 'Hva finnes hvor'
        tabell_tekst = 'Funksjon'
        rader = [('Farger, toner, harmonier, overganger og paletter', ja, ja, ja),
                 ('Kontrast (WCAG, APCA og LRV) og fargesyn', ja, ja, ja),
                 ('Presentasjonsmodus: større tekst og kontroller for prosjektør og skjermdeling' + N, ja, ja, ja),
                 ('Simuler farger og paletter under andre betraktningsforhold', ja, ja, ja),
                 ('Fargeflatene ved siden av verktøyene', nei, 'I liggende format', 'I bredt vindu'),
                 ('Palettene for hånden, med dra og slipp', nei, 'På store iPader', ja),
                 ('Plukk farger med kameraet', ja, ja, 'Innebygd kamera eller iPhone'),
                 ('Kompenser for lyset med gråkort og referansekort', ja, ja, 'Med iPhone som kamera'),
                 ('Mål fargetemperatur og belysningsstyrke', ja, ja, nei),
                 ('Pipette for hele skjermen', nei, nei, ja),
                 ('Lyskilde for kameraet', 'Lykt', 'Lykt der den finnes', 'Lysfelt på skjermen'),
                 ('Apple Intelligence på enheten¹', ja, ja, ja),
                 ('Siri og Snarveier', ja, ja, ja)]
        fotnote = '¹ Der Apple Intelligence er tilgjengelig. Ellers brukes den innebygde kunnskapsbasen.'
        krav = 'Krever iOS 26, iPadOS 26 eller macOS 26.'
    else:
        tittel = 'iPhone, iPad and Mac – Kolorist'
        beskr = 'Kolorist is one app for iPhone, iPad and Mac. Use one or several – your palettes, viewing conditions and profiles follow along through iCloud.'
        h1 = 'iPhone, iPad and Mac'
        ingress = 'One app for iPhone, iPad and Mac. Use it on the device you have – or on several, with your palettes, viewing conditions and profiles synced through iCloud.'
        styrker_tittel = 'Each device has its strength'
        styrker = [('iPhone', 'Always with you: pick colours with the camera, measure the light and simulate colours in other viewing conditions.'),
                   ('iPad', 'More room: in landscape the swatches sit beside the tools, and on large iPads your palettes are at hand.'),
                   ('Mac', 'Wide window: an eyedropper for the whole screen and swatches you drag straight into other apps.')]
        sammen_tittel = 'Together'
        sammen = ['Palettes, single colours and gradients follow you between devices through your own iCloud',
                  'ICC profiles and colour libraries live in the app’s folder in iCloud Drive',
                  'Measure the light with iPhone or iPad – and see colours in the same light on the Mac' + N12,
                  'Use iPhone as the camera on the Mac, with compensation for the light' + N12,
                  'Your view layout follows along',
                  'Colleagues on PCs: save palettes in the formats they use, in a folder in the cloud service you share' + N12,
                  'Shared links open in the app on iPhone, iPad and Mac – and in the browser elsewhere, PCs included' + N12]
        side_tittel = 'Side by side'
        side_intro = 'The same tools, fitted to the screen.'
        visninger = [('studio', 'Studio'), ('harmoni', 'Harmony'), ('overgang', 'Gradient'),
                     (None, 'Contrast: WCAG, APCA or LRV'), (None, 'Pick a colour from a colour field'),
                     (None, 'Presentation mode')]
        tabell_tittel = 'What is where'
        tabell_tekst = 'Feature'
        rader = [('Colours, tones, harmonies, gradients and palettes', ja, ja, ja),
                 ('Contrast (WCAG, APCA and LRV) and colour vision', ja, ja, ja),
                 ('Presentation mode: larger text and controls for projectors and screen sharing' + N, ja, ja, ja),
                 ('Simulate colours and palettes in other viewing conditions', ja, ja, ja),
                 ('Swatches beside the tools', nei, 'In landscape', 'In a wide window'),
                 ('Palettes at hand, with drag and drop', nei, 'On large iPads', ja),
                 ('Pick colours with the camera', ja, ja, 'Built-in camera or iPhone'),
                 ('Compensate for the light with grey and reference cards', ja, ja, 'With iPhone as the camera'),
                 ('Measure colour temperature and illuminance', ja, ja, nei),
                 ('Eyedropper for the whole screen', nei, nei, ja),
                 ('Light source for the camera', 'Torch', 'Torch where available', 'Light panel on screen'),
                 ('Apple Intelligence on device¹', ja, ja, ja),
                 ('Siri and Shortcuts', ja, ja, ja)]
        fotnote = '¹ Where Apple Intelligence is available. Otherwise the built-in knowledge base is used.'
        krav = 'Requires iOS 26, iPadOS 26 or macOS 26.'

    pre = '' if nb else '../'
    ipadmappe = 'assets/ipad' if nb else '../assets/en/ipad'
    styrke_html = '\n'.join(f"""        <li>
          <h3>{n}</h3>
          <p>{tx}</p>
        </li>""" for n, tx in styrker)
    sammen_html = '\n'.join(f'        <li>{x}</li>' for x in sammen)
    rader_vis = []
    kommer = 'Skjermskudd kommer' if nb else 'Screenshot coming'
    for navn, vis in visninger:
        if navn is None:
            # Plassholder til skjermbildene er tatt, i hver plattforms format.
            iph, ipad, mac = (f'<div class="ramme">{kommer}</div>',) * 3
            id_ = re.sub(r'[^a-z0-9]+', '-', vis.lower().translate(str.maketrans('æøå', 'eoa'))).strip('-')
        else:
            iph, _ = iphonebilde(s, navn)
            mac = macbilde(s, navn)
            iph = re.sub(r'alt="[^"]*"', f'alt="{vis} – iPhone"', iph)
            mac = re.sub(r'alt="[^"]*"', f'alt="{vis} – Mac"', mac)
            ipad = f'<img src="{ipadmappe}/skjermbilde-{navn}.png?v=6" alt="{vis} – iPad" width="1032" height="1376" loading="lazy">'
            id_ = navn
        rader_vis.append(f"""      <section class="sammenligning" aria-labelledby="vis-{id_}">
        <h3 id="vis-{id_}">{vis}</h3>
        <div class="sammenligning-bilder">
          <figure class="skjermbilde iphone">
            {iph}
            <figcaption>iPhone</figcaption>
          </figure>
          <figure class="skjermbilde ipad">
            {ipad}
            <figcaption>iPad</figcaption>
          </figure>
          <figure class="skjermbilde mac">
            {mac}
            <figcaption>Mac</figcaption>
          </figure>
        </div>
      </section>""")
    KYST = "https://kolorist.no/l#znZJLTsMwEIavYlliFxw_M-PuaEpZVLAoK4S6CCWUkL6UtIiq6nE4CRdjnAfKmo09Htuf5v9nzvyNj57PvKRVCmMSqaJrKaQ2XWCVShYR3xz5iCs5ZlqY2AjLI76lzOS0Z28fu-qVzl_hxdTc2Am_RD3RKatNAzI-cS0Rve6JINyYWUJaAR1ydqoPL-uf745opsktugERLEjf1uhtGxh0dlgjEE71FRZ1sWLvxWaTrzskTscmhQESPSgVEUhqMGHXCL4HauGeGAqM1Z_qx2zbC75NJmmKQ8FeIxJDaZANEw2agdw5c7GSwneoh-xYHyiuKC6Wy1GZ3qW79a563GfL_C7f5lWxTO-fZuFJeN-m6pL1yUOjmcUMkBbUtOircPFJ5SgZAUaoo2B4KDdF5wz1h46rpu8ZH0EnqjxuqmK7or91c0WD8a-5GM5B8GXAAaCeBVPAtbvXSg2NnjMQOsY_zlR7cpg4i1ByYxgNW9Bfnhrfgvx9ts4P4UCS1eUX"
    if nb:
        del_tittel, del_ingress = 'Del med andre – også uten appen', 'Farger, paletter, gradienter og harmonier kan deles som lenke. Fargene ligger i selve lenken – kolorist.no lagrer og ser ingenting.'
        del_punkter = ['Med Kolorist åpnes lenken i appen på iPhone, iPad og Mac, med forhåndsvisning – ingenting lagres før du velger det',
                       'Uten appen – også på PC – vises fargene i nettleseren, med hex, OKLCH, CIELab og Munsell, klare til å kopieres',
                       'Filamentfarger lenker videre til prøven hos kilden',
                       'Tonenavn fra fargekart du har importert, tas ikke med – bare fargeverdiene deles',
                       'Lagre som: filer i formatene du velger, i en mappe du velger – eller del dem direkte']
        del_knapp = 'Åpne en delt eksempelpalett ↗'
    else:
        del_tittel, del_ingress = 'Share with others – even without the app', 'Colours, palettes, gradients and harmonies can be shared as a link. The colours are in the link itself – kolorist.no stores and sees nothing.'
        del_punkter = ['With Kolorist the link opens in the app on iPhone, iPad and Mac, with a preview – nothing is saved until you choose',
                       'Without the app – on PCs too – the colours are shown in the browser, with hex, OKLCH, CIELab and Munsell, ready to copy',
                       'Filament colours link on to the sample at the source',
                       'Tone names from colour charts you have imported are left out – only the colour values are shared',
                       'Save as: files in the formats you choose, in a folder you choose – or share them directly']
        del_knapp = 'Open a shared example palette ↗'
    del_bilder = []
    for navn in ('del-app', 'del-web', 'del-web-filament'):
        img, tekst_b = iphonebilde(s, navn)
        del_bilder.append(f'''        <li>
          <figure class="skjermbilde">
            {img}
            <figcaption>{tekst_b}</figcaption>
          </figure>
        </li>''')
    delseksjon = f'''    <section class="seksjon" id="del" aria-labelledby="del-tittel">
      <h2 id="del-tittel">{del_tittel}</h2>
      <p class="lesetekst">{del_ingress}</p>
      <ul class="lesetekst">
''' + '\n'.join(f'        <li>{x}</li>' for x in del_punkter) + f'''
      </ul>
      <p><a class="knapp knapp-sekundaer" href="{KYST}">{del_knapp}</a></p>
      <ul class="skjermbilder tre">
''' + '\n'.join(del_bilder) + '''
      </ul>
    </section>
'''
    tabellrader = '\n'.join(f'            <tr><th scope="row">{a}</th><td>{b}</td><td>{c}</td><td>{d}</td></tr>' for a, b, c, d in rader)
    innhold = f"""    <header class="sidetopp">
      <h1>{h1}</h1>
      <p class="ingress">{ingress}</p>
      <ul class="plattformer" aria-label="{'Plattformer' if nb else 'Platforms'}">
        <li>iPhone</li>
        <li>iPad</li>
        <li>Mac</li>
      </ul>
    </header>

    <section class="seksjon" aria-labelledby="styrker">
      <h2 id="styrker">{styrker_tittel}</h2>
      <ul class="poeng">
{styrke_html}
      </ul>
    </section>

    <section class="seksjon lesetekst" aria-labelledby="sammen">
      <h2 id="sammen">{sammen_tittel}</h2>
      <ul>
{sammen_html}
      </ul>
    </section>

{delseksjon}
    <section class="seksjon" aria-labelledby="side-om-side">
      <h2 id="side-om-side">{side_tittel}</h2>
      <p class="dempet">{side_intro}</p>
{chr(10).join(rader_vis)}
    </section>

    <section class="seksjon" aria-labelledby="hva-hvor">
      <h2 id="hva-hvor">{tabell_tittel}</h2>
      <div class="tabell-omslag">
        <table class="plattformtabell">
          <thead>
            <tr><th scope="col">{tabell_tekst}</th><th scope="col">iPhone</th><th scope="col">iPad</th><th scope="col">Mac</th></tr>
          </thead>
          <tbody>
{tabellrader}
          </tbody>
        </table>
      </div>
      <p class="dempet">{fotnote}</p>
      <div class="handlinger">
        {nedlastknapp(s)}
      </div>
      <p class="dempet">{krav}</p>
    </section>
"""
    return side(lang, 'plattformer.html' if nb else 'platforms.html', tittel, beskr, innhold)


# ---------- 3D-print og filament ----------

def filamentside(lang):
    N = f' <span class="nytt">{T[lang]["nytt"]}</span>'
    FIL = "https://kolorist.no/l#znZNdb5swFIb_iuWrTWL-NgbuEkK2SVNbrb3oNPWCBtKiAM7AdE2j_vc5gSASOkXKDdg-9nnPc157C5cw-L2FK_sliHucSOcLQYS5rmgHvi8fHFg0MIAKySlgyMMMKejA0i5N3poqnWd5Aa6r7Ckr4xxcxS8bMM2bFHy6-TH5bDf-gcEW5nb3szHrOsB4meVxkZZmoXNd1eh184brv7FZPGPGBcP2SGF329Odyji3DWgYmKpJHbge1mEDtZ3PO4WwV4DvDny1ETYVnhR2doCWlO5JBaOqHUhCj5AF4lggcUA2usgW4KAA7rQGX7VOgNHgMb2YXAglxuQfJB-hH9fz_wY40CQwYEh2neAzN_LYoBMekdTvXFftPeCUqqNeKKQwR7Ir7zZLkrYLN3Ft0vxieq6EP6YfJD2l7pXPGj7hoTuTA0yf-C53LBxhbP9nXu-37c4v4CEf095vPru_i8Jv4DYrmkddXobnkg-u9SHjKVuneM5JW2KHGE0iEs4GiC6hOzLKFdkTei5zBzb-BBJRTGn_jMPr6B58L5dpVWr7kuPy6SJMSuiY8jjtKetO-ayF4Vxybvke2oxXukqyegVWm9qADLRSxgbWcZ6a3Y14sd15_wc"
    kilde = '<a href="https://filamentcolors.xyz/">FilamentColors.xyz</a>'
    lisens = '<a href="https://creativecommons.org/licenses/by/4.0/">CC BY 4.0</a>'
    if lang == 'nb':
        steg = [
            ('Finn filamentet', 'Velg «Filament: alle typer» under «Vis som», og se nærmeste filament til fargen din – eller søk innen ett materiale.',
             [f'Over 2 200 filamentfarger fra 150 produsenter, fra {kilde}' + N12,
              'Alle typer samlet, eller ett bibliotek per materiale: PLA, PETG, ABS og ASA, TPU og TPE og andre',
              'Nærmeste filament etter ΔE00, med avstanden oppgitt',
              'De fleste fargene er målt med kolorimeter; resten er anslått fra foto og merket slik'], 'filament', None),
            ('Bygg paletter som kan skrives ut', 'Lås farger, toner og harmonier til filamenter som finnes.',
             ['Harmonier og toner låses til nærmeste filament',
              'Lagrede farger tar med produsent, navn, materiale og lenke til prøven',
              '«Se fargen hos FilamentColors.xyz» på hver farge – der finner du bilder og mer om filamentet',
              'Fargene varierer mellom produksjonspartier og etter overflate – se på en fysisk prøve før du bestemmer deg'], None, None),
            ('Del med lenke', 'Del en palett med filamentfarger som lenke. Mottakere uten appen ser fargene i nettleseren, med vei videre til hver prøve.',
             ['Med Kolorist åpnes lenken i appen, og du velger selv hva som lagres',
              'Uten appen – også på PC – vises fargene på kolorist.no, med produsent, materiale og lenke til kilden',
              'Kilden og lisensen oppgis på siden'], 'del-web-filament', (FIL, 'Se eksempelet «Nordisk kyst i PLA»')),
            ('Åpent om dataene', 'Hvor fargene kommer fra, og hva Kolorist gjør med dem.',
             [f'Kilde: {kilde}, lisensiert under {lisens} – Kolorist har valgt ut opplysninger og regnet om fargene',
              'Målt som CIELab under D65 med 10°-observatør, og regnet om til Kolorists fargerom med Bradford-tilpasning',
              'Uttrekket følger med appen og oppdateres med nye versjoner; appen henter ingenting fra nettet',
              'Kolorist er ikke tilknyttet FilamentColors.xyz'], None, ('methods.html#filamentfarger', 'Les om metoden')),
        ]
        return fagside('nb', 'filament.html', 'Kolorist for 3D-print – filamentfarger fra 150 produsenter',
                       'Finn nærmeste filament til fargene dine: over 2 200 filamentfarger fra 150 produsenter, de fleste målt med kolorimeter, med lenke til hver prøve.',
                       'Kolorist for', '3D-print og filament',
                       'Fra fargen på skjermen til filamentet på spolen: finn nærmeste filament blant over 2 200 farger, bygg paletter som kan skrives ut, og del dem med lenke videre til hver prøve.',
                       steg, ('Les videre', [('design.html', 'Kolorist for design'), ('plattformer.html#del', 'Del med andre'), ('funksjoner.html', 'Alle funksjoner')]))
    steg = [
        ('Find the filament', 'Choose “Filament: all types” under “Show as”, and see the nearest filament to your colour – or search within one material.',
         [f'More than 2,200 filament colours from 150 manufacturers, from {kilde}' + N12,
          'All types together, or one library per material: PLA, PETG, ABS and ASA, TPU and TPE and others',
          'Nearest filament by ΔE00, with the distance shown',
          'Most colours are measured with a colorimeter; the rest are estimated from photos and marked as such'], 'filament', None),
        ('Build palettes you can print', 'Lock colours, tones and harmonies to filaments that exist.',
         ['Harmonies and tones are locked to the nearest filament',
          'Saved colours keep the manufacturer, name, material and a link to the sample',
          '“See the colour at FilamentColors.xyz” on every colour – with photos and more about the filament',
          'Colours vary between production batches and with surface finish – look at a physical sample before you decide'], None, None),
        ('Share with a link', 'Share a palette of filament colours as a link. Recipients without the app see the colours in their browser, with a way on to each sample.',
         ['With Kolorist the link opens in the app, and you decide what to save',
          'Without the app – on PCs too – the colours are shown at kolorist.no, with manufacturer, material and a link to the source',
          'The source and licence are stated on the page'], 'del-web-filament', (FIL, 'See the example “Nordisk kyst in PLA”')),
        ('Open about the data', 'Where the colours come from, and what Kolorist does with them.',
         [f'Source: {kilde}, licensed under {lisens} – Kolorist has selected information and converted the colours',
          'Measured as CIELab under D65 with the 10° observer, and converted to Kolorist’s colour space with Bradford adaptation',
          'The extract ships with the app and is updated with new versions; the app fetches nothing from the internet',
          'Kolorist is not affiliated with FilamentColors.xyz'], None, ('methods.html#filamentfarger', 'Read about the method')),
    ]
    return fagside('en', 'filament.html', 'Kolorist for 3D printing – filament colours from 150 manufacturers',
                   'Find the nearest filament to your colours: more than 2,200 filament colours from 150 manufacturers, most measured with a colorimeter, with a link to each sample.',
                   'Kolorist for', '3D printing and filament',
                   'From the colour on screen to the filament on the spool: find the nearest filament among more than 2,200 colours, build palettes you can print, and share them with a link on to each sample.',
                   steg, ('Read on', [('design.html', 'Kolorist for design'), ('platforms.html#del', 'Share with others'), ('features.html', 'All features')]))


# ---------- Skriv ----------

def skriv(sti, tekst):
    # Nye skjermbilder: ny versjon i adressen, så nettleser og Varnish henter dem på nytt.
    tekst = re.sub(r'\.png\?v=\d+', '.png?v=8', tekst)
    open(f'{W}/{sti}', 'w').write(tekst)


skriv('index.html', startside('nb'))
skriv('en/index.html', startside('en'))
skriv('design.html', design('nb'))
skriv('en/design.html', design('en'))
skriv('arkitektur.html', arkitektur('nb'))
skriv('en/architecture.html', arkitektur('en'))
skriv('lys.html', lysside('nb'))
skriv('en/light.html', lysside('en'))
skriv('filament.html', filamentside('nb'))
skriv('en/filament.html', filamentside('en'))
skriv('plattformer.html', plattformer('nb'))
skriv('en/platforms.html', plattformer('en'))
skriv('funksjoner.html', funksjoner('nb'))
skriv('en/features.html', funksjoner('en'))

# Eksisterende sider: ny meny og bunnmeny, nytt stilark.
for lang, mappe in (('nb', ''), ('en', 'en/')):
    for fil in ('support.html', 'privacy.html', 'terms.html', 'methods.html'):
        sti = f'{W}/{mappe}{fil}'
        h = open(sti).read()
        h = re.sub(r'<nav class="hovednav".*?</nav>', hovednav(lang, fil), h, count=1, flags=re.S)
        h = re.sub(r'<nav aria-label="(Bunnmeny|Footer menu)">.*?</nav>', bunnnav(lang, fil), h, count=1, flags=re.S)
        h = re.sub(r'stil\.css\?v=\d+', 'stil.css?v=6', h)
        h = h.replace('index.html#lys', 'lys.html' if lang == 'nb' else 'light.html')
        open(sti, 'w').write(h)

# Nettstedskart
sider = ['', 'design.html', 'arkitektur.html', 'plattformer.html', 'filament.html', 'lys.html', 'funksjoner.html', 'support.html', 'privacy.html', 'terms.html', 'methods.html']
linjer = []
for nbfil in sider:
    enfil = PAR.get(nbfil or 'index.html')
    linjer.append(f'  <url><loc>https://kolorist.no/{nbfil}</loc><lastmod>2026-10-04</lastmod></url>')
    linjer.append(f'  <url><loc>https://kolorist.no/en/{"" if enfil == "index.html" else enfil}</loc><lastmod>2026-10-04</lastmod></url>')
open(f'{W}/sitemap.xml', 'w').write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + '\n'.join(linjer) + '\n</urlset>\n')
print('ok')
