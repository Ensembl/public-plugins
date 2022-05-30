import { html, css, LitElement } from 'https://unpkg.com/lit@2.2.5/index.js?module';

import './controlPanel.js';

export class VepVariantControlPanel extends LitElement {

  static get properties() {
    return {
      label: { attribute: false },
      position: { attribute: false },
      consequence: { attribute: false }
    }
  }

  render() {
    return html`
      <control-panel title="Variant">
        <div class="body">
          <table class="details">
            <thead>
              <tr>
                <th>Label</th>
                <th>Location</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>${this.label}</td>
                <td>${this.position}</td>
                <td>${this.consequence}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </control-panel>
    `;
  }

}

customElements.define('vep-variant-control-panel', VepVariantControlPanel);
