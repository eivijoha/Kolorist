// Rolig karusell for skjermbilder: kryssfading omtrent hvert 7. sekund. Stopper når pekeren eller tastaturfokus er
// i karusellen, har egen pauseknapp og prikker for hvert bilde, og går ikke av seg selv når «Reduser bevegelse» er på.
// Uten skript vises bildene som en sidelengs rull (se .karusell i stil.css).
(function () {
  var INTERVALL = 7000;
  var redusert = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  document.querySelectorAll('[data-karusell]').forEach(function (k) {
    var bilder = Array.prototype.slice.call(k.querySelectorAll('.karusell-bilder > li'));
    if (bilder.length < 2) return;
    var tekst = {
      pause: k.getAttribute('data-pause') || 'Pause',
      spill: k.getAttribute('data-spill') || 'Spill av',
      bilde: k.getAttribute('data-bilde') || 'Vis bilde'
    };
    var aktiv = 0, tidtaker = null, stoppetAvBruker = redusert, svever = false;

    k.classList.add('i-gang');
    var kontroller = document.createElement('div');
    kontroller.className = 'karusell-kontroller';
    var knapp = document.createElement('button');
    knapp.type = 'button';
    knapp.className = 'karusell-pause';
    kontroller.appendChild(knapp);
    var prikker = bilder.map(function (li, i) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'karusell-prikk';
      var navn = (li.querySelector('figcaption') || {}).textContent || String(i + 1);
      b.setAttribute('aria-label', tekst.bilde + ' ' + (i + 1) + ': ' + navn);
      b.addEventListener('click', function () { vis(i); stoppetAvBruker = true; oppdaterKnapp(); stopp(); });
      kontroller.appendChild(b);
      return b;
    });
    k.appendChild(kontroller);

    function vis(i) {
      aktiv = (i + bilder.length) % bilder.length;
      bilder.forEach(function (li, n) {
        li.classList.toggle('vist', n === aktiv);
        li.setAttribute('aria-hidden', n === aktiv ? 'false' : 'true');
      });
      prikker.forEach(function (p, n) { p.setAttribute('aria-current', n === aktiv ? 'true' : 'false'); });
    }
    function start() { if (!tidtaker && !stoppetAvBruker && !svever) tidtaker = setInterval(function () { vis(aktiv + 1); }, INTERVALL); }
    function stopp() { clearInterval(tidtaker); tidtaker = null; }
    function oppdaterKnapp() {
      knapp.textContent = stoppetAvBruker ? '▶' : '❚❚';
      knapp.setAttribute('aria-label', stoppetAvBruker ? tekst.spill : tekst.pause);
      k.setAttribute('aria-live', stoppetAvBruker ? 'polite' : 'off');
    }
    knapp.addEventListener('click', function () {
      stoppetAvBruker = !stoppetAvBruker;
      oppdaterKnapp();
      if (stoppetAvBruker) { stopp(); } else { vis(aktiv + 1); start(); }
    });
    k.addEventListener('mouseenter', function () { svever = true; stopp(); });
    k.addEventListener('mouseleave', function () { svever = false; start(); });
    k.addEventListener('focusin', function () { svever = true; stopp(); });
    k.addEventListener('focusout', function (e) { if (!k.contains(e.relatedTarget)) { svever = false; start(); } });

    vis(0);
    oppdaterKnapp();
    start();
  });
})();
