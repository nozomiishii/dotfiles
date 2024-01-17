// ==UserScript==
// @name         ad block
// @namespace    nozomiishii
// @version      0.1
// @description  ad block
// @author       Nozomi Ishii
// @match        https://tanstack.com/*
// @icon         https://www.nozomiishii.dev/icons/android-chrome-192x192.png
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  window.onload = (event) => {
    setTimeout(function () {
      const ads = document.getElementById('carbonads');
      if (ads) {
        ads.style.display = 'none';
      }
    }, 1000);
  };
})();
