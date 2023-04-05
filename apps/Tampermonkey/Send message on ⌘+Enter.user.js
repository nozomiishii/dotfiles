// ==UserScript==
// @name         Send message on ⌘+Enter
// @namespace    nozomiishii
// @version      0.1
// @description  Send message on ⌘+Enter
// @author       Nozomi Ishii
// @match        https://chat.openai.com/chat*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=openai.com
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    document.querySelector('form')
      .addEventListener('keydown', (e) => {
      if (e.code === "Enter" && !e.metaKey) {
        e.stopPropagation();
      }
    }, { capture: true });

    document.querySelector('textarea')
      .addEventListener('keydown', (e) => {
      if (e.code === "Enter" && !e.metaKey) {
        e.stopPropagation();
      }
    }, { capture: true });
})();