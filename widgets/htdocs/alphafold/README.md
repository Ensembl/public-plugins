# Description
This folder contains code for a widget to display 3d protein structures predicted by the Alphafold AI.

The widget uses `pdbe-molstar` as a viewer of 3D protein molecules, and wraps it in a UI relevant for Ensembl pages. The widget is built as a custom web component, using the `lit` library for convenience (to enable reactive properties on the HTML element). The code is written in modern javascript syntax that should work the browsers that support `<script type="module" />` (around 95% of web browsers).

The widget is loaded from the `htdocs/components/95_AFDB.js` file. The top-level component (see `index.js`) is does not have shadow DOM, because shadow DOM prevents events from leaving the component, whereas the `pdbe-molstar` viewer uses an older version of React, whose events need to bubble up all the way to the `document` object to be registered. As a consequence of that, the CSS required by the top-level component is placed in `95_AFDB.css`, along with the relevant CSS variables for theming. Other components use shadow DOM, and contain their own styles.

## References
See pdbe-molstar usage examples:
- As a plugin on Plunkr: https://embed.plnkr.co/plunk/WlRx73uuGA9EJbpn
- Helper documentation: https://github.com/PDBeurope/pdbe-molstar/wiki
  - for use as a separate JS instance: https://github.com/PDBeurope/pdbe-molstar/wiki/1.-PDBe-Molstar-as-JS-plugin
  - for use as a web component: https://github.com/PDBeurope/pdbe-molstar/wiki/2.-PDBe-Molstar-as-Web-component
   */
