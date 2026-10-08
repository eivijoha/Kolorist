// Kolorist – visning av delte lenker (https://kolorist.no/l#z…).
//
// Innholdet ligger etter # og sendes aldri til nettstedet. Formatet er det samme som appen skriver
// (FargeKjerne/Deling/Delingslenke.swift): JSON med korte nøkler, rå DEFLATE, base64url, med «z» foran.
// Testlenkene i Pakker/FargeKjerne/Tests/FargeKjerneTests/Testlenker.json gjelder også her.
// Tekst fra lenken settes alltid inn som tekst (textContent), aldri som HTML.
"use strict";

(() => {
  const MAKS_TEGN = 32000;
  const MAKS_UTPAKKET = 1 << 20;
  const MAKS_FARGER = 256;

  // Språket: det Kolorist kjørte på hos avsenderen (feltet «sp» i lenken), ellers nettleserens – norsk for norske
  // nettlesere, ellers engelsk.
  const erNorsk = (kode) => /^(nb|no|nn)\b/.test((kode || "").toLowerCase());
  let en, T, HARMONIER, SIRKLER;
  function settSpråk(engelsk) {
  en = engelsk;
  T = en ? {
    hopp: "Skip to main content", laster: "Opening …", haAppen: "Do you have Kolorist?",
    haAppenTekst: "Open the link in the app to save, edit and build on it.",
    aapne: (en1) => en1 ? "Open the colour in the Kolorist app" : "Open the colours in the Kolorist app",
    lastNed: "Download for iPhone, iPad and Mac",
    personvern: "The colours are in the link itself. Kolorist.no doesn’t know what is shared.",
    farge: "Colour", palett: "Palette", gradient: "Gradient", harmoni: "Harmony", farger: (n) => n === 1 ? "1 colour" : `${n} colours`,
    stopp: (n) => `${n} colour stops`, utenNavn: "Untitled",
    kopierHex: "Copy hex", kopierAlle: "Copy all as hex", kopierCSS: "Copy as CSS", kopiert: "Copied",
    feilTittel: "The link couldn’t be read",
    feilTekst: "It may be cut short, or made with a newer version of Kolorist. Ask the sender to share it again.",
    ingenTittel: "Nothing shared", ingenTekst: "This page shows colours, palettes, gradients and harmonies shared from Kolorist.",
    sirkel: "Colour wheel", delt: "Shared from Kolorist", toner: (n) => `${n} tones`,
    produsent: "Manufacturer", materiale: "Material", måling: "Measurement", målt: "Measured", anslått: "Estimated",
    seKilde: (k) => `See the colour at ${k}`,
    kreditering: "Filament colours from", lisens: "licensed under",
    designsystem: "Design system", komponenter: "Components", roller: "Role colours", tokens: "Colours per mode",
    kontroll: "Contrast checks (WCAG 2, AA)", alleHolder: "All colour pairs meet the requirement",
    holderIkke: (n) => n === 1 ? "1 colour pair falls short" : `${n} colour pairs fall short`,
    moduser: { light: "Light", dark: "Dark", "light-ic": "Light, increased contrast", "dark-ic": "Dark, increased contrast" },
    eks: { tittel: "Settings", varsler: "Notifications", konto: "Account", navn: "Name", lagre: "Save", avbryt: "Cancel",
      lenke: "Read more about privacy", slett: "Delete account", hjelp: "Notifications also appear on the Lock Screen.",
      feil: "Name is missing", ok: "Your changes are saved", advarsel: "Storage is almost full", hjem: "Home", søk: "Search" },
    par: { tekst: "Text on surface", sekundær: "Helper text on background", plassholder: "Placeholder in text field",
      lenke: "Link on background", destruktiv: "Delete action on background", knapp: "Text on primary button",
      tonet: "Text on secondary button", kant: "Text field border", bryter: "Switch that is on", fokus: "Focus ring",
      feil: "Error message", suksess: "Confirmation", advarsel: "Warning", varsel: "Alert", egenKnapp: "Text on button",
      etikettkant: "Label border", etikettekst: "Label text" },
    token: "Token", minst: "at least", kopierTokens: "Copy as CSS",
    dsTekst: "Open the link in Kolorist to save the design system and export it to app development, design tools and the web.",
    aapneDs: "Open the design system in the Kolorist app",
  } : {
    hopp: "Hopp til hovedinnhold", laster: "Åpner …", haAppen: "Har du Kolorist?",
    haAppenTekst: "Åpne lenken i appen for å lagre, endre og bygge videre.",
    aapne: (en1) => en1 ? "Åpne fargen i Kolorist-appen" : "Åpne fargene i Kolorist-appen",
    lastNed: "Last ned for iPhone, iPad og Mac",
    personvern: "Fargene ligger i selve lenken. Kolorist.no får ikke vite hva som deles.",
    farge: "Farge", palett: "Palett", gradient: "Gradient", harmoni: "Harmoni", farger: (n) => n === 1 ? "1 farge" : `${n} farger`,
    stopp: (n) => `${n} fargestopp`, utenNavn: "Uten navn",
    kopierHex: "Kopier hex", kopierAlle: "Kopier alle som hex", kopierCSS: "Kopier som CSS", kopiert: "Kopiert",
    feilTittel: "Lenken kunne ikke leses",
    feilTekst: "Den kan være avkortet, eller laget med en nyere versjon av Kolorist. Be avsenderen dele den på nytt.",
    ingenTittel: "Ingenting delt", ingenTekst: "Denne siden viser farger, paletter, gradienter og harmonier delt fra Kolorist.",
    sirkel: "Fargesirkel", delt: "Delt fra Kolorist", toner: (n) => `${n} toner`,
    produsent: "Produsent", materiale: "Materiale", måling: "Måling", målt: "Målt", anslått: "Anslått",
    seKilde: (k) => `Se fargen hos ${k}`,
    kreditering: "Filamentfarger fra", lisens: "lisensiert under",
    designsystem: "Designsystem", komponenter: "Komponenter", roller: "Rollefarger", tokens: "Farger per modus",
    kontroll: "Kontrast (WCAG 2, AA)", alleHolder: "Alle fargepar holder kravet",
    holderIkke: (n) => n === 1 ? "1 fargepar holder ikke kravet" : `${n} fargepar holder ikke kravet`,
    moduser: { light: "Lys", dark: "Mørk", "light-ic": "Lys, økt kontrast", "dark-ic": "Mørk, økt kontrast" },
    eks: { tittel: "Innstillinger", varsler: "Varsler", konto: "Konto", navn: "Navn", lagre: "Lagre", avbryt: "Avbryt",
      lenke: "Les mer om personvern", slett: "Slett konto", hjelp: "Varsler vises også på låseskjermen.",
      feil: "Navnet mangler", ok: "Endringene er lagret", advarsel: "Lagringsplassen er snart full", hjem: "Hjem", søk: "Søk" },
    par: { tekst: "Tekst på flate", sekundær: "Hjelpetekst på bakgrunnen", plassholder: "Plassholder i tekstfelt",
      lenke: "Lenke på bakgrunnen", destruktiv: "Slettehandling på bakgrunnen", knapp: "Tekst på hovedknapp",
      tonet: "Tekst på sekundærknapp", kant: "Kant på tekstfelt", bryter: "Bryter som er på", fokus: "Fokusring",
      feil: "Feilmelding", suksess: "Bekreftelse", advarsel: "Advarsel", varsel: "Varsel", egenKnapp: "Tekst på knapp",
      etikettkant: "Kant på etikett", etikettekst: "Tekst på etikett" },
    token: "Token", minst: "minst", kopierTokens: "Kopier som CSS",
    dsTekst: "Åpne lenken i Kolorist for å lagre designsystemet og eksportere det til apputvikling, designverktøy og nettet.",
    aapneDs: "Åpne designsystemet i Kolorist-appen",
  };
  HARMONIER = en ? {
    komplementær: "Complementary", splittKomplementær: "Split complementary", analog: "Analogous",
    analogMedAksent: "Analogous with accent", triade: "Triad", kvadrat: "Square",
    dobbeltKomplementær: "Double complementary", jevn: "Even distribution",
  } : {
    komplementær: "Komplementær", splittKomplementær: "Split-komplementær", analog: "Analog",
    analogMedAksent: "Analog med aksent", triade: "Triade", kvadrat: "Kvadrat",
    dobbeltKomplementær: "Dobbelt komplementær", jevn: "Jevn fordeling",
  };
  SIRKLER = en ? {
    okLCH: "OKLCH (perceptual)", cieLCH: "CIE LCH (Lab)", hsl: "HSL (RGB screen)", ryb: "RYB (artist's wheel)",
    munsell: "Munsell", hering: "Hering (opponent colours)",
  } : {
    okLCH: "OKLCH (perseptuell)", cieLCH: "CIE LCH (Lab)", hsl: "HSL (RGB-skjerm)", ryb: "RYB (kunstnersirkel)",
    munsell: "Munsell", hering: "Hering (motfarger)",
  };
  }
  settSpråk(!erNorsk(navigator.language || "nb"));

  // ---------- Lesing av lenken ----------

  function fraBase64url(s) {
    if (!/^[A-Za-z0-9_-]*$/.test(s)) throw new Error("tegn");
    let b = s.replace(/-/g, "+").replace(/_/g, "/");
    while (b.length % 4) b += "=";
    const bin = atob(b);
    const ut = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) ut[i] = bin.charCodeAt(i);
    return ut;
  }

  async function pakkUt(bytes) {
    const strøm = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
    const leser = strøm.getReader();
    const deler = [];
    let total = 0;
    for (;;) {
      const { done, value } = await leser.read();
      if (done) break;
      total += value.length;
      if (total >= MAKS_UTPAKKET) { leser.cancel(); throw new Error("for stor"); }
      deler.push(value);
    }
    const alt = new Uint8Array(total);
    let i = 0;
    for (const d of deler) { alt.set(d, i); i += d.length; }
    return new TextDecoder().decode(alt);
  }

  const erTall = (x) => typeof x === "number" && Number.isFinite(x);
  const erFarge = (f) => f && Array.isArray(f.k) && f.k.length === 3 && f.k.every(erTall)
    && f.k[0] >= -0.5 && f.k[0] <= 1.5 && Math.abs(f.k[1]) <= 1 && Math.abs(f.k[2]) <= 1
    && (f.a === undefined || (erTall(f.a) && f.a >= 0 && f.a <= 1));
  // Kildelenker godtas bare til kjente kilder (som i appen: DeltKilde.godkjenteVerter).
  const GODKJENTE_VERTER = ["filamentcolors.xyz"];
  function godkjentLenke(tekstverdi) {
    try {
      const u = new URL(tekstverdi);
      return u.protocol === "https:" && GODKJENTE_VERTER.includes(u.hostname.toLowerCase()) ? u.href : null;
    } catch { return null; }
  }
  const tekst = (s) => typeof s === "string" ? s.replace(/[\u0000-\u001F\u007F-\u009F]/g, "").slice(0, 200) : "";

  async function les(fragment) {
    if (fragment.length > MAKS_TEGN || fragment[0] !== "z") throw new Error("format");
    const d = JSON.parse(await pakkUt(fraBase64url(fragment.slice(1))));
    if (!d || typeof d !== "object" || !erTall(d.v)) throw new Error("format");
    const farger = Array.isArray(d.f) ? d.f : [];
    const gradienter = Array.isArray(d.g) ? d.g : [];
    const antall = farger.length + gradienter.reduce((n, g) => n + (Array.isArray(g.s) ? g.s.length : 0), 0);
    if (antall > MAKS_FARGER) throw new Error("for mange");
    if (!farger.every(erFarge)) throw new Error("farge");
    for (const g of gradienter) {
      if (!Array.isArray(g.s) || g.s.length < 2 || g.s.length > 64) throw new Error("gradient");
      if (!g.s.every((s) => erFarge(s.f) && (s.p === undefined || (erTall(s.p) && s.p >= 0 && s.p <= 1)))) throw new Error("stopp");
    }
    if (!["farge", "palett", "gradient", "harmoni"].includes(d.t)) throw new Error("slag");
    return { versjon: d.v, slag: d.t, navn: tekst(d.n), farger, gradienter, harmoni: d.h && typeof d.h === "object" ? d.h : null,
             designsystem: lesDesignsystem(d.ds, farger.length), språk: typeof d.sp === "string" && /^[a-z]{1,3}$/.test(d.sp) ? d.sp : null };
  }

  const MODUSER = ["light", "dark", "light-ic", "dark-ic"];
  const erHex = (x) => typeof x === "string" && /^[0-9A-Fa-f]{6}$/.test(x);

  // Et designsystem i lenken (fra 1.3): tokennavn og ferdige farger per modus. Ugyldig = vis lenken som palett.
  function lesDesignsystem(ds, antallFarger) {
    if (!ds || typeof ds !== "object" || !Array.isArray(ds.tn) || ds.tn.length > 64) return null;
    if (!ds.tn.every((n) => typeof n === "string" && /^[a-z0-9.-]{1,80}$/.test(n))) return null;
    const tm = ds.tm && typeof ds.tm === "object" ? ds.tm : null;
    if (!tm || !MODUSER.every((m) => Array.isArray(tm[m]) && tm[m].length === ds.tn.length && tm[m].every(erHex))) return null;
    const egne = (Array.isArray(ds.e) ? ds.e : []).slice(0, 4).filter((e) => e && erTall(e.i) && e.i >= 0 && e.i < antallFarger
      && typeof e.t === "string" && /^[a-z0-9-]{1,60}$/.test(e.t) && ["status", "aksent", "markering"].includes(e.m))
      .map((e) => ({ navn: tekst(e.n), token: e.t, mal: e.m }));
    const moduser = {};
    for (const m of MODUSER) {
      moduser[m] = new Map(ds.tn.map((n, i) => [n, `#${tm[m][i].toUpperCase()}`]));
    }
    return { tokennavn: ds.tn, moduser, egne };
  }

  // ---------- Fargeregning (samme matriser som appen) ----------

  const mul = (m, v) => [0, 1, 2].map((i) => m[i][0] * v[0] + m[i][1] * v[1] + m[i][2] * v[2]);
  const matmul = (a, b) => [0, 1, 2].map((i) => [0, 1, 2].map((j) => a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j]));
  function inv(m) {
    const [a, b, c] = m[0], [d, e, f] = m[1], [g, h, i] = m[2];
    const A = e * i - f * h, B = -(d * i - f * g), C = d * h - e * g;
    const det = a * A + b * B + c * C;
    return [[A / det, -(b * i - c * h) / det, (b * f - c * e) / det],
            [B / det, (a * i - c * g) / det, -(a * f - c * d) / det],
            [C / det, -(a * h - b * g) / det, (a * e - b * d) / det]];
  }
  const SRGB_XYZ = [[506752 / 1228815, 87881 / 245763, 12673 / 70218],
                    [87098 / 409605, 175762 / 245763, 12673 / 175545],
                    [7918 / 409605, 87881 / 737289, 1001167 / 1053270]];
  const HVIT_D65 = [0.3127 / 0.3290, 1, (1 - 0.3127 - 0.3290) / 0.3290];
  const HVIT_D50 = [0.3457 / 0.3585, 1, (1 - 0.3457 - 0.3585) / 0.3585];
  const BRADFORD = (() => {
    const mA = [[0.8951, 0.2664, -0.1614], [-0.7502, 1.7135, 0.0367], [0.0389, -0.0685, 1.0296]];
    const k = mul(mA, HVIT_D65), m = mul(mA, HVIT_D50);
    return matmul(inv(mA), matmul([[m[0] / k[0], 0, 0], [0, m[1] / k[1], 0], [0, 0, m[2] / k[2]]], mA));
  })();

  function lineærSRGB([L, a, b]) {
    const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    const s_ = L - 0.0894841775 * a - 1.2914855480 * b;
    const l = l_ ** 3, m = m_ ** 3, s = s_ ** 3;
    return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s];
  }

  function cieLab(k) {
    const xyz = mul(BRADFORD, mul(SRGB_XYZ, lineærSRGB(k)));
    const e = 216 / 24389, kappa = 24389 / 27;
    const f = xyz.map((v, i) => { const t = v / HVIT_D50[i]; return t > e ? Math.cbrt(t) : (kappa * t + 16) / 116; });
    return [116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2])];
  }

  function okLCH([L, a, b]) {
    const c = Math.hypot(a, b);
    let h = Math.atan2(b, a) * 180 / Math.PI;
    if (h < 0) h += 360;
    return [L, c, h];
  }

  const css = (f) => `oklab(${f.k[0]} ${f.k[1]} ${f.k[2]}${f.a !== undefined ? ` / ${f.a}` : ""})`;
  const hex = (f) => f.x && /^[0-9A-Fa-f]{6}$/.test(f.x) ? `#${f.x.toUpperCase()}` : null;
  const tall = (x, d) => (en ? x.toFixed(d) : x.toFixed(d).replace(".", ","));

  // ---------- Visning ----------

  const lag = (tag, klasse, innhold) => {
    const el = document.createElement(tag);
    if (klasse) el.className = klasse;
    if (innhold !== undefined) el.textContent = innhold;
    return el;
  };

  async function kopier(knapp, verdi) {
    try {
      await navigator.clipboard.writeText(verdi);
      const før = knapp.textContent;
      knapp.textContent = T.kopiert;
      setTimeout(() => { knapp.textContent = før; }, 1500);
    } catch { /* utklippstavlen er ikke tilgjengelig */ }
  }

  function fargekort(f) {
    const kort = lag("li", "delt-farge");
    const prøve = lag("div", "delt-prove");
    prøve.style.background = hex(f) || "#808080";
    prøve.style.background = css(f);
    kort.append(prøve);
    if (f.n) kort.append(lag("h3", null, tekst(f.n)));
    const verdier = lag("dl", "delt-verdier");
    const rad = (navn, verdi) => { verdier.append(lag("dt", null, navn), lag("dd", null, verdi)); };
    const [L, C, H] = okLCH(f.k);
    const lab = cieLab(f.k);
    if (f.rt && f.rn) rad(tekst(f.rn), tekst(f.rt));
    if (hex(f)) rad("Hex (sRGB)", hex(f));
    rad("OKLCH", `${tall(L * 100, 0)}% ${tall(C, 3)} ${tall(H, 0)}°`);
    rad("CIELab (D50)", `${tall(lab[0], 1)} ${tall(lab[1], 1)} ${tall(lab[2], 1)}`);
    if (f.mu && f.rn !== "Munsell") rad("Munsell", tekst(f.mu));
    const q = f.q && typeof f.q === "object" ? f.q : null;
    if (q) {
      if (q.p) rad(T.produsent, tekst(q.p));
      if (q.m) rad(T.materiale, tekst(q.m));
      if (typeof q.o === "boolean") rad(T.måling, q.o ? T.målt : T.anslått);
    }
    kort.append(verdier);
    const lenke = q ? godkjentLenke(q.l) : null;
    if (lenke) {
      const a = lag("a", "knapp knapp-sekundaer delt-kilde", `${T.seKilde(tekst(q.s) || new URL(lenke).hostname)} ↗`);
      a.href = lenke;
      a.rel = "noopener noreferrer";
      a.target = "_blank";
      kort.append(a);
    }
    if (hex(f)) {
      const knapp = lag("button", "delt-kopier", T.kopierHex);
      knapp.type = "button";
      knapp.addEventListener("click", () => kopier(knapp, hex(f)));
      kort.append(knapp);
    }
    kort.dataset.hex = hex(f) || "";
    kort.dataset.oklch = [L, C, H].join(",");
    kort.dataset.lab = lab.join(",");
    return kort;
  }

  const kebab = (s, i) => (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/æ/gi, "ae").replace(/ø/gi, "o")
    .toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || `farge-${i + 1}`;

  function cssForFarger(farger) {
    const brukt = new Map();
    const linjer = farger.map((f, i) => {
      let navn = kebab(f.n, i);
      const n = (brukt.get(navn) || 0) + 1;
      brukt.set(navn, n);
      if (n > 1) navn += `-${n}`;
      const [L, C, H] = okLCH(f.k);
      return `  --${navn}: ${hex(f) || "#808080"};\n  --${navn}: oklch(${L.toFixed(4)} ${C.toFixed(4)} ${H.toFixed(2)});`;
    });
    return `:root {\n${linjer.join("\n")}\n}`;
  }

  function gradientCSS(g) {
    const n = g.s.length;
    const stopp = g.s.map((s, i) => `${css(s.f)} ${((s.p ?? (i / (n - 1))) * 100).toFixed(1)}%`).join(", ");
    return `linear-gradient(90deg in oklab, ${stopp})`;
  }

  function knapperad(knapper) {
    const rad = lag("div", "handlinger delt-knapper");
    for (const [etikett, verdi] of knapper) {
      const k = lag("button", "knapp knapp-sekundaer", etikett);
      k.type = "button";
      k.addEventListener("click", () => kopier(k, verdi));
      rad.append(k);
    }
    return rad;
  }

  function vis(d) {
    const innhold = document.getElementById("innhold");
    const tittel = document.getElementById("tittel");
    const slag = document.getElementById("slag");
    const første = d.farger[0];
    tittel.textContent = d.slag === "farge" ? (tekst(første?.n) || hex(første) || T.farge)
      : d.slag === "gradient" ? (tekst(d.gradienter[0]?.n) || T.gradient)
      : (d.navn || (d.slag === "palett" ? T.palett : T.harmoni));
    slag.textContent = d.slag === "palett" ? `${T.palett} · ${T.farger(d.farger.length)}`
      : d.slag === "harmoni" ? [T.harmoni, HARMONIER[d.harmoni?.h], SIRKLER[d.harmoni?.s]].filter(Boolean).join(" · ")
      : T[d.slag];
    if (d.designsystem) {
      slag.textContent = `${T.designsystem} · ${T.delt}`;
    }
    document.title = `${tittel.textContent} – ${T.delt}`;
    if (d.designsystem) {
      visDesignsystem(d);
      for (const id of ["aapneTopp", "aapne"]) {
        const a = document.getElementById(id);
        a.href = `kolorist://l${location.hash}`;
        a.textContent = T.aapneDs;
      }
      const p = document.querySelector("#handlinger p");
      if (p) p.textContent = T.dsTekst;
      document.getElementById("topphandling").hidden = false;
      document.getElementById("handlinger").hidden = false;
      return;
    }

    if (d.farger.length > 1) {
      // Hele paletten under ett, før kortene med verdier.
      const stripe = lag("div", "delt-oversikt");
      stripe.setAttribute("aria-hidden", "true");
      for (const f of d.farger) {
        const felt = lag("span");
        felt.style.background = hex(f) || "#808080";
        felt.style.background = css(f);
        stripe.append(felt);
      }
      innhold.append(stripe);
    }
    if (d.farger.length) {
      const liste = lag("ul", "delt-farger");
      d.farger.forEach((f) => liste.append(fargekort(f)));
      innhold.append(liste);
      if (d.farger.length > 1) {
        innhold.append(knapperad([[T.kopierAlle, d.farger.map((f) => hex(f) || "").join("\n")], [T.kopierCSS, cssForFarger(d.farger)]]));
      }
    }
    for (const g of d.gradienter) {
      const seksjon = lag("section", "delt-gradient");
      if (d.slag !== "gradient" && g.n) seksjon.append(lag("h2", null, tekst(g.n)));
      const stripe = lag("div", "delt-stripe");
      stripe.style.background = `linear-gradient(90deg, ${g.s.map((s) => hex(s.f) || "#808080").join(", ")})`;
      stripe.style.background = gradientCSS(g);
      seksjon.append(stripe);
      const info = [T.stopp(g.s.length)];
      if (erTall(g.a)) info.push(T.toner(g.a));
      seksjon.append(lag("p", "dempet", info.join(" · ")));
      const liste = lag("ul", "delt-farger");
      g.s.forEach((s) => liste.append(fargekort(s.f)));
      seksjon.append(liste);
      seksjon.append(knapperad([[T.kopierCSS, `background: ${gradientCSS(g)};`]]));
      innhold.append(seksjon);
    }
    // Kreditering når lenken har farger fra FilamentColors.xyz (CC BY 4.0).
    const alleFarger = d.farger.concat(...d.gradienter.map((g) => g.s.map((x) => x.f)));
    if (alleFarger.some((f) => f.q && godkjentLenke(f.q.l))) {
      const p = lag("p", "dempet delt-kreditering");
      const kilde = lag("a", null, "FilamentColors.xyz");
      kilde.href = "https://filamentcolors.xyz/";
      kilde.rel = "noopener noreferrer";
      const lisens = lag("a", null, "CC BY 4.0");
      lisens.href = "https://creativecommons.org/licenses/by/4.0/";
      lisens.rel = "noopener noreferrer";
      p.append(`${T.kreditering} `, kilde, `, ${T.lisens} `, lisens, ".");
      innhold.append(p);
    }
    // «Åpne i appen» øverst og nederst; universelle lenker åpner appen direkte, dette er for innebygde nettlesere.
    const enFarge = d.slag === "farge";
    for (const id of ["aapneTopp", "aapne"]) {
      const a = document.getElementById(id);
      a.href = `kolorist://l${location.hash}`;
      a.textContent = T.aapne(enFarge);
    }
    document.getElementById("topphandling").hidden = false;
    document.getElementById("handlinger").hidden = false;
  }

  // ---------- Designsystem ----------

  function luminans(h) {
    const k = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255)
      .map((v) => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
    return 0.2126 * k[0] + 0.7152 * k[1] + 0.0722 * k[2];
  }
  function forhold(a, b) {
    const la = luminans(a), lb = luminans(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }
  // Som i appen: avkortet (ikke avrundet) til to desimaler, så 4,499 aldri vises som 4,50.
  const forholdTekst = (x) => `${tall(Math.floor(x * 100) / 100, 2)}:1`;

  function stil(el, verdier) { for (const [k, v] of Object.entries(verdier)) el.style[k] = v; return el; }

  // En liten app-skjerm med fargene i én modus, som komponentvisningen i appen.
  function komponenter(c, egne) {
    const E = T.eks;
    const skjerm = stil(lag("div", "ds-skjerm"), { background: c("background.page"), color: c("text.primary") });
    skjerm.append(stil(lag("h3", "ds-tittel", E.tittel), { color: c("text.primary") }));
    const liste = stil(lag("div", "ds-liste"), { background: c("background.surface") });
    const ikon = () => stil(lag("span", "ds-ikon"), { background: c("background.accent"), color: c("text.on-accent") });
    const rad1 = lag("div", "ds-rad");
    const i1 = ikon(); i1.textContent = "●";
    const bryter = stil(lag("span", "ds-bryter"), { background: c("background.switch-on") });
    bryter.append(lag("span", "ds-knott"));
    rad1.append(i1, lag("span", "ds-fyll", E.varsler), bryter);
    const skille = stil(lag("div", "ds-skille"), { background: c("border.separator") });
    const rad2 = lag("div", "ds-rad");
    const i2 = ikon(); i2.textContent = "●";
    rad2.append(i2, lag("span", "ds-fyll", E.konto), stil(lag("span", null, "Kari ›"), { color: c("text.secondary") }));
    liste.append(rad1, skille, rad2);
    skjerm.append(liste, stil(lag("p", "ds-hjelp", E.hjelp), { color: c("text.secondary") }));
    skjerm.append(stil(lag("div", "ds-felt", E.navn), {
      background: c("background.surface"), color: c("text.placeholder"), borderColor: c("border.control") }));
    const knapper = lag("div", "ds-knapper");
    knapper.append(stil(lag("span", "ds-knapp", E.lagre), { background: c("background.accent"), color: c("text.on-accent") }),
      stil(lag("span", "ds-knapp", E.avbryt), { background: c("background.accent-subtle"), color: c("text.accent") }));
    for (const e of egne.filter((x) => x.mal === "aksent")) {
      knapper.append(stil(lag("span", "ds-knapp", e.navn), { background: c(`background.${e.token}`), color: c(`text.on-${e.token}`) }));
    }
    skjerm.append(knapper);
    const lenker = lag("div", "ds-lenker");
    lenker.append(stil(lag("span", "ds-lenke", E.lenke), { color: c("text.accent") }), stil(lag("span", null, E.slett), { color: c("text.danger") }));
    skjerm.append(lenker);
    const varsel = (navn, tekstinnhold, tegn) => {
      const v = stil(lag("div", "ds-varsel"), { background: c(`background.${navn}`), color: c(`text.${navn}`) });
      v.append(lag("span", "ds-tegn", tegn), lag("span", null, tekstinnhold));
      return v;
    };
    skjerm.append(varsel("danger", E.feil, "✕"), varsel("success", E.ok, "✓"), varsel("warning", E.advarsel, "!"));
    for (const e of egne.filter((x) => x.mal === "status")) skjerm.append(varsel(e.token, e.navn, "i"));
    const merker = egne.filter((x) => x.mal === "markering");
    if (merker.length) {
      const rad = lag("div", "ds-etiketter");
      for (const e of merker) {
        const et = stil(lag("span", "ds-etikett"), { background: c(`background.${e.token}`), borderColor: c(`border.${e.token}`), color: c("text.primary") });
        et.append(stil(lag("span", "ds-prikk"), { background: c(`border.${e.token}`) }), lag("span", null, e.navn));
        rad.append(et);
      }
      skjerm.append(rad);
    }
    const faner = stil(lag("div", "ds-faner"), { background: c("background.surface"), borderColor: c("border.separator") });
    faner.append(stil(lag("span", null, E.hjem), { color: c("text.accent") }), stil(lag("span", null, E.søk), { color: c("text.secondary") }),
      stil(lag("span", null, E.tittel), { color: c("text.secondary") }));
    skjerm.append(faner);
    skjerm.setAttribute("aria-hidden", "true");
    return skjerm;
  }

  // Fargeparene i komponentene (normal tilstand), med kravet etter WCAG 2.
  function fargepar(egne) {
    const P = T.par;
    const par = [
      [P.tekst, "text.primary", "background.surface", 4.5, "1.4.3"],
      [P.sekundær, "text.secondary", "background.page", 4.5, "1.4.3"],
      [P.plassholder, "text.placeholder", "background.surface", 4.5, "1.4.3"],
      [P.lenke, "text.accent", "background.page", 4.5, "1.4.3"],
      [P.destruktiv, "text.danger", "background.page", 4.5, "1.4.3"],
      [P.knapp, "text.on-accent", "background.accent", 4.5, "1.4.3"],
      [P.tonet, "text.accent", "background.accent-subtle", 4.5, "1.4.3"],
      [P.kant, "border.control", "background.surface", 3, "1.4.11"],
      [P.bryter, "background.switch-on", "background.surface", 3, "1.4.11"],
      [P.fokus, "border.focus", "background.surface", 3, "1.4.11"],
      [P.feil, "text.danger", "background.danger", 4.5, "1.4.3"],
      [P.suksess, "text.success", "background.success", 4.5, "1.4.3"],
      [P.advarsel, "text.warning", "background.warning", 4.5, "1.4.3"],
    ];
    for (const e of egne) {
      if (e.mal === "status") par.push([`${P.varsel}: ${e.navn}`, `text.${e.token}`, `background.${e.token}`, 4.5, "1.4.3"]);
      if (e.mal === "aksent") par.push([`${P.egenKnapp}: ${e.navn}`, `text.on-${e.token}`, `background.${e.token}`, 4.5, "1.4.3"]);
      if (e.mal === "markering") {
        par.push([`${P.etikettkant}: ${e.navn}`, `border.${e.token}`, "background.surface", 3, "1.4.11"]);
        par.push([`${P.etikettekst}: ${e.navn}`, "text.primary", `background.${e.token}`, 4.5, "1.4.3"]);
      }
    }
    return par;
  }

  function visDesignsystem(d) {
    const ds = d.designsystem;
    const innhold = document.getElementById("innhold");
    let modus = "light";
    const farge = (navn) => ds.moduser[modus].get(`color.${navn}`) || "#808080";

    const velger = lag("div", "ds-moduser");
    velger.setAttribute("role", "group");
    const knapper = MODUSER.map((m) => {
      const k = lag("button", "knapp knapp-sekundaer", T.moduser[m]);
      k.type = "button";
      k.addEventListener("click", () => { modus = m; tegn(); });
      velger.append(k);
      return [m, k];
    });

    const flate = lag("div", "ds-oppsett");
    const skjermplass = lag("div");
    const kontroll = lag("section", "ds-kontroll");
    flate.append(skjermplass, kontroll);

    function tegn() {
      for (const [m, k] of knapper) k.setAttribute("aria-pressed", String(m === modus));
      skjermplass.replaceChildren(komponenter(farge, ds.egne));
      const par = fargepar(ds.egne).map(([navn, fg, bg, min, kriterium]) => {
        const f = ds.moduser[modus].get(`color.${fg}`), b = ds.moduser[modus].get(`color.${bg}`);
        return { navn, f, b, min, kriterium, x: f && b ? forhold(f, b) : null };
      }).filter((p) => p.x !== null);
      const feiler = par.filter((p) => p.x < p.min).length;
      kontroll.replaceChildren(lag("h2", null, T.kontroll),
        lag("p", feiler ? "ds-status ds-feiler" : "ds-status", feiler ? T.holderIkke(feiler) : T.alleHolder));
      const ul = lag("ul", "ds-par");
      for (const p of par) {
        const li = lag("li");
        li.append(stil(lag("span", "ds-prove", "Aa"), { background: p.b, color: p.f }));
        const tekstdel = lag("span", "ds-partekst");
        tekstdel.append(lag("span", null, p.navn), lag("span", "dempet", `${p.kriterium} · ${T.minst} ${tall(p.min, p.min === 3 ? 0 : 1)}:1`));
        li.append(tekstdel, lag("strong", p.x >= p.min ? "ds-ok" : "ds-ikke", `${p.x >= p.min ? "✓" : "✕"} ${forholdTekst(p.x)}`));
        ul.append(li);
      }
      kontroll.append(ul);
    }

    innhold.append(lag("h2", null, T.komponenter), velger, flate);
    tegn();

    // Alle tokens i alle moduser, og CSS med light-dark() og prefers-contrast som i eksporten fra appen.
    const tabSeksjon = lag("section", "ds-tokens");
    tabSeksjon.append(lag("h2", null, T.tokens));
    const omslag = lag("div", "tabell-omslag");
    const tabell = lag("table");
    const hode = lag("tr");
    hode.append(lag("th", null, T.token), ...MODUSER.map((m) => lag("th", null, T.moduser[m])));
    tabell.append(lag("thead"));
    tabell.tHead.append(hode);
    const kropp = lag("tbody");
    for (const n of ds.tokennavn) {
      const tr = lag("tr");
      tr.append(lag("td", "ds-tokennavn", n));
      for (const m of MODUSER) {
        const h = ds.moduser[m].get(n);
        const td = lag("td");
        td.append(stil(lag("span", "ds-ruteprove"), { background: h }), lag("code", null, h));
        tr.append(td);
      }
      kropp.append(tr);
    }
    tabell.append(kropp);
    omslag.append(tabell);
    tabSeksjon.append(omslag);
    const cssnavn = (n) => `--${n.replace(/\./g, "-")}`;
    const blokk = (a, b, innrykk) => ds.tokennavn.map((n) => `${innrykk}${cssnavn(n)}: light-dark(${ds.moduser[a].get(n)}, ${ds.moduser[b].get(n)});`).join("\n");
    const cssTekst = `:root {\n  color-scheme: light dark;\n${blokk("light", "dark", "  ")}\n}\n\n@media (prefers-contrast: more) {\n  :root {\n${blokk("light-ic", "dark-ic", "    ")}\n  }\n}\n`;
    tabSeksjon.append(knapperad([[T.kopierTokens, cssTekst]]));
    innhold.append(tabSeksjon);

    // Rollefargene, som kort med verdier.
    const rolleSeksjon = lag("section");
    rolleSeksjon.append(lag("h2", null, T.roller));
    const liste = lag("ul", "delt-farger");
    d.farger.forEach((f) => liste.append(fargekort(f)));
    rolleSeksjon.append(liste);
    innhold.append(rolleSeksjon);
  }

  function visFeil(tittelTekst, tekstInnhold) {
    document.getElementById("tittel").textContent = tittelTekst;
    document.getElementById("innhold").append(lag("p", "lesetekst", tekstInnhold));
    document.getElementById("handlinger").hidden = false;
    document.getElementById("aapne").hidden = true;
  }

  // Tekstene i sidens faste HTML og lenken til forsiden, på valgt språk.
  function brukSpråk() {
    document.documentElement.lang = en ? "en" : "nb";
    document.querySelectorAll("[data-t]").forEach((el) => { if (typeof T[el.dataset.t] === "string") el.textContent = T[el.dataset.t]; });
    document.querySelectorAll("[data-href-en]").forEach((el) => {
      if (!el.dataset.hrefNb) el.dataset.hrefNb = el.getAttribute("href");
      el.setAttribute("href", en ? el.dataset.hrefEn : el.dataset.hrefNb);
    });
  }

  async function start() {
    brukSpråk();
    const fragment = location.hash.slice(1);
    if (!fragment) { visFeil(T.ingenTittel, T.ingenTekst); return; }
    try {
      const d = await les(fragment);
      window.koloristDelt = d;   // for testene
      // Språket avsenderens Kolorist kjørte på, når lenken har det.
      if (d.språk) { settSpråk(!erNorsk(d.språk)); brukSpråk(); }
      vis(d);
    } catch (e) {
      window.koloristFeil = String(e);
      visFeil(T.feilTittel, T.feilTekst);
    }
  }

  window.addEventListener("hashchange", () => location.reload());
  start();
})();
