/**
 * Lions International theme - front-end behaviour.
 *
 * Deliberately small and dependency-free:
 *  - mobile off-canvas navigation (focus management, Escape, inert background)
 *  - accordion submenus inside the mobile navigation
 *  - primary navigation dropdowns (toggle button for touch/keyboard, Escape to close)
 *  - header search popover
 *  - compact header after scrolling
 */
(function () {
  'use strict';

  var doc = document;
  var body = doc.body;
  var header = doc.querySelector('[data-header]');
  var DESKTOP = window.matchMedia('(min-width: 64em)');

  function $(selector, scope) {
    return (scope || doc).querySelector(selector);
  }

  function $$(selector, scope) {
    return Array.prototype.slice.call((scope || doc).querySelectorAll(selector));
  }

  function setExpanded(button, expanded) {
    button.setAttribute('aria-expanded', expanded ? 'true' : 'false');
  }

  function isExpanded(button) {
    return button.getAttribute('aria-expanded') === 'true';
  }

  /* ---------------------------------------------------------------------
   * Mobile navigation
   * ------------------------------------------------------------------- */
  var navToggle = $('[data-mobile-nav-toggle]');
  var navPanel = $('[data-mobile-nav]');
  var main = $('#main');
  var footer = $('.site-footer');

  function openMobileNav() {
    navPanel.hidden = false;
    setExpanded(navToggle, true);
    body.classList.add('has-open-nav');
    [main, footer].forEach(function (el) { if (el) { el.setAttribute('inert', ''); } });
    var first = navPanel.querySelector('a, button');
    if (first) { first.focus(); }
  }

  function closeMobileNav(returnFocus) {
    if (!navPanel || navPanel.hidden) { return; }
    navPanel.hidden = true;
    setExpanded(navToggle, false);
    body.classList.remove('has-open-nav');
    [main, footer].forEach(function (el) { if (el) { el.removeAttribute('inert'); } });
    if (returnFocus) { navToggle.focus(); }
  }

  if (navToggle && navPanel) {
    navToggle.addEventListener('click', function () {
      if (navPanel.hidden) { openMobileNav(); } else { closeMobileNav(true); }
    });

    $$('[data-accordion-toggle]', navPanel).forEach(function (button) {
      var target = doc.getElementById(button.getAttribute('aria-controls'));
      if (!target) { return; }
      button.addEventListener('click', function () {
        var open = !isExpanded(button);
        setExpanded(button, open);
        target.hidden = !open;
      });
    });

    // Close when the viewport grows to desktop size.
    DESKTOP.addEventListener('change', function (event) {
      if (event.matches) { closeMobileNav(false); }
    });
  }

  /* ---------------------------------------------------------------------
   * Primary navigation dropdowns
   * ------------------------------------------------------------------- */
  var dropdownToggles = $$('[data-dropdown-toggle]');

  function closeDropdown(button) {
    setExpanded(button, false);
    button.parentNode.classList.remove('is-open');
  }

  function closeAllDropdowns(except) {
    dropdownToggles.forEach(function (button) {
      if (button !== except) { closeDropdown(button); }
    });
  }

  dropdownToggles.forEach(function (button) {
    var item = button.parentNode;

    button.addEventListener('click', function () {
      var open = !isExpanded(button);
      closeAllDropdowns(button);
      setExpanded(button, open);
      item.classList.toggle('is-open', open);
    });

    // Leaving the item with the keyboard closes it.
    item.addEventListener('focusout', function (event) {
      if (!item.contains(event.relatedTarget)) { closeDropdown(button); }
    });
  });

  /* ---------------------------------------------------------------------
   * Header search popover
   * ------------------------------------------------------------------- */
  var searchToggle = $('[data-search-toggle]');
  var searchPanel = $('[data-search-panel]');
  var searchWrap = $('[data-search]');

  function closeSearch(returnFocus) {
    if (!searchPanel || searchPanel.hidden) { return; }
    searchPanel.hidden = true;
    setExpanded(searchToggle, false);
    if (returnFocus) { searchToggle.focus(); }
  }

  if (searchToggle && searchPanel) {
    searchToggle.addEventListener('click', function () {
      var open = searchPanel.hidden;
      searchPanel.hidden = !open;
      setExpanded(searchToggle, open);
      if (open) {
        var input = searchPanel.querySelector('input');
        if (input) { input.focus(); }
      }
    });

    doc.addEventListener('click', function (event) {
      if (searchWrap && !searchWrap.contains(event.target)) { closeSearch(false); }
    });
  }

  /* ---------------------------------------------------------------------
   * Escape closes whatever is open; clicks outside close dropdowns
   * ------------------------------------------------------------------- */
  doc.addEventListener('keydown', function (event) {
    if (event.key !== 'Escape') { return; }
    closeMobileNav(true);
    closeSearch(true);
    dropdownToggles.forEach(function (button) {
      if (isExpanded(button)) {
        closeDropdown(button);
        button.focus();
      }
    });
  });

  doc.addEventListener('click', function (event) {
    if (!event.target.closest('.primary-nav__item')) { closeAllDropdowns(null); }
  });

  /* ---------------------------------------------------------------------
   * Compact header after scrolling (desktop)
   * ------------------------------------------------------------------- */
  if (header && 'IntersectionObserver' in window) {
    var sentinel = doc.createElement('div');
    sentinel.setAttribute('aria-hidden', 'true');
    sentinel.style.cssText = 'position:absolute;top:0;left:0;height:120px;width:1px;pointer-events:none;';
    body.insertBefore(sentinel, body.firstChild);

    var observer = new IntersectionObserver(function (entries) {
      header.classList.toggle('is-compact', !entries[0].isIntersecting);
    });
    observer.observe(sentinel);
  }
})();
