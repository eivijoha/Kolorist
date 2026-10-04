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

  // Norsk for norske nettlesere, ellers engelsk.
  const en = !/^(nb|no|nn)\b/.test((navigator.language || "nb").toLowerCase());
  const T = en ? {
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
  };
  const HARMONIER = en ? {
    komplementær: "Complementary", splittKomplementær: "Split complementary", analog: "Analogous",
    analogMedAksent: "Analogous with accent", triade: "Triad", kvadrat: "Square",
    dobbeltKomplementær: "Double complementary", jevn: "Even distribution",
  } : {
    komplementær: "Komplementær", splittKomplementær: "Split-komplementær", analog: "Analog",
    analogMedAksent: "Analog med aksent", triade: "Triade", kvadrat: "Kvadrat",
    dobbeltKomplementær: "Dobbelt komplementær", jevn: "Jevn fordeling",
  };
  const SIRKLER = en ? {
    okLCH: "OKLCH (perceptual)", cieLCH: "CIE LCH (Lab)", hsl: "HSL (RGB screen)", ryb: "RYB (artist's wheel)",
    munsell: "Munsell", hering: "Hering (opponent colours)",
  } : {
    okLCH: "OKLCH (perseptuell)", cieLCH: "CIE LCH (Lab)", hsl: "HSL (RGB-skjerm)", ryb: "RYB (kunstnersirkel)",
    munsell: "Munsell", hering: "Hering (motfarger)",
  };

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
    return { versjon: d.v, slag: d.t, navn: tekst(d.n), farger, gradienter, harmoni: d.h && typeof d.h === "object" ? d.h : null };
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
      const a = lag("a", "delt-kilde", T.seKilde(tekst(q.s) || new URL(lenke).hostname));
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
    document.title = `${tittel.textContent} – ${T.delt}`;

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

  function visFeil(tittelTekst, tekstInnhold) {
    document.getElementById("tittel").textContent = tittelTekst;
    document.getElementById("innhold").append(lag("p", "lesetekst", tekstInnhold));
    document.getElementById("handlinger").hidden = false;
    document.getElementById("aapne").hidden = true;
  }

  async function start() {
    if (en) {
      document.documentElement.lang = "en";
      document.querySelectorAll("[data-t]").forEach((el) => { if (typeof T[el.dataset.t] === "string") el.textContent = T[el.dataset.t]; });
      document.querySelectorAll("[data-href-en]").forEach((el) => { el.href = el.dataset.hrefEn; });
    }
    const fragment = location.hash.slice(1);
    if (!fragment) { visFeil(T.ingenTittel, T.ingenTekst); return; }
    try {
      const d = await les(fragment);
      window.koloristDelt = d;   // for testene
      vis(d);
    } catch (e) {
      window.koloristFeil = String(e);
      visFeil(T.feilTittel, T.feilTekst);
    }
  }

  window.addEventListener("hashchange", () => location.reload());
  start();
})();
