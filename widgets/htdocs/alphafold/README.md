# Description
This folder contains code for a widget to display 3d protein structures predicted by the Alphafold AI.

The widget is built as a web component using the Lit library for convenience (to enable reactive properties on the HTML element). The code is using modern javascript syntax that should work in over 90% of web browsers.

The widget is loaded from the `htdocs/components/95_AFDB.js` file. The top-level component (in `index.js` file) is built without shadow DOM, because the pdbe-molstar viewer uses an older version of React, whose events need to be propagated all the way to the `document` to be registered, and shadow DOM would prevent that. Because of that, the CSS required by this component is placed in the `95_AFDB.css` file. Other components use shadow DOM and encapsulate the styles within themselves.

## References
See Molstar usage examples:
- As a plugin on Plunkr: https://embed.plnkr.co/plunk/WlRx73uuGA9EJbpn
- Helper documentation: https://github.com/PDBeurope/pdbe-molstar/wiki
  - for use as a separate JS instance: https://github.com/PDBeurope/pdbe-molstar/wiki/1.-PDBe-Molstar-as-JS-plugin
  - for use as a web component: https://github.com/PDBeurope/pdbe-molstar/wiki/2.-PDBe-Molstar-as-Web-component
   */
