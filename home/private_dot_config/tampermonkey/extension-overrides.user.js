// ==UserScript==
// @name         Extension overrides
// @namespace    nozomiishii
// @version      0.1
// @description  Extension overrides
// @author       Nozomi Ishii
// @match        https://*/*
// @exclude      https://*.sbisec.co.jp/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=openai.com
// @grant        none
// ==/UserScript==

function overrideExtensionConfig() {
  setTimeout(() => {
    // ---------------------------------------------------------
    // Speechify
    // ---------------------------------------------------------
    const nudge = document.getElementById('speechify-listening-nudge');
    const button = nudge ? nudge.shadowRoot.querySelector('button[aria-label="Speechify nudge dismiss"]') : null;

    if (button) {
      button.click();
    }

    const nudges = document.querySelectorAll('[id^="speechify-first-word-listening-nudge-"]');

    if (nudges.length > 0) {
      nudges.forEach(function (element) {
        element.style.pointerEvents = 'none';
      });
    }

    // ---------------------------------------------------------
    // ads
    // ---------------------------------------------------------
    const ads = document.getElementById('carbonads');

    if (ads) {
      ads.style.display = 'none';
    }
  }, 1000);
}

(function () {
  'use strict';

  // 現在のURLを保存
  let lastUrl = window.location.href;

  // 監視器のインスタンスを作成してURL変更の監視
  const observer = new MutationObserver((mutationsList) => {
    for (const mutation of mutationsList) {
      if (mutation.type === 'childList' && window.location.href !== lastUrl) {
        lastUrl = window.location.href;
        overrideExtensionConfig();
      }
    }
  });

  observer.observe(document.body, { childList: true, subtree: true });

  window.onload = overrideExtensionConfig;
})();
