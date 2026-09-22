// Ignore accidental repeated clicks without delaying the first interaction.
(function () {
  const clicks = new Map();
  document.addEventListener('click', function (event) {
    const button = event.target.closest('.action-button, .shiny-download-link');
    if (!button) return;
    const now = Date.now();
    if (now - (clicks.get(button.id) || 0) < 700) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }
    clicks.set(button.id, now);
  }, true);
  $(document).on('shiny:connected', function () {
    // Shiny's modalDialog() doesn't wire aria-labelledby to its own title, so screen readers
    // get no accessible name for the dialog on open. Bootstrap fires this on every modalDialog show.
    $(document).on('shown.bs.modal', '#shiny-modal', function () {
      var title = this.querySelector('.modal-title');
      if (title) {
        if (!title.id) title.id = 'shiny-modal-title';
        this.setAttribute('aria-labelledby', title.id);
      }
    });
    Shiny.addCustomMessageHandler('demo-stage', function (message) {
      window.scrollTo(0, 0);
      // conditionalPanel's own visibility toggle reacts to the same flush this message rides in on,
      // and isn't guaranteed to have applied yet when this handler runs; defer to the next paint
      // (same double-rAF wait already proven below for the visNetwork resize) before reading it.
      requestAnimationFrame(function () { requestAnimationFrame(function () {
        // Screen-reader users get no cue from the scroll alone; move focus to the new stage's
        // heading so it gets announced. preventScroll avoids fighting the scrollTo above.
        var headings = document.querySelectorAll('main.workspace h2');
        var visible = Array.prototype.find.call(headings, function (h) { return h.offsetParent !== null; });
        if (visible) {
          if (!visible.hasAttribute('tabindex')) visible.setAttribute('tabindex', '-1');
          visible.focus({ preventScroll: true });
        }
        // visNetwork initializes at 0x0 while its conditionalPanel is hidden; force a redraw once visible.
        window.dispatchEvent(new Event('resize'));
      }); });
    });
    Shiny.addCustomMessageHandler('demo-reset', function (message) {
      clicks.clear();
      document.querySelectorAll('details').forEach(function (el) { el.open = el.classList.contains('final-dag'); });
      document.querySelectorAll('.shiny-notification').forEach(function (el) { el.remove(); });
      window.scrollTo(0, 0);
    });
  });
})();
