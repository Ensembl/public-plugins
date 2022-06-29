import { html, css, LitElement } from 'https://unpkg.com/lit@2.2.5/index.js?module';

import './controlPanel.js';

export class VepVariantControlPanel extends LitElement {

  static get styles() {

    return css`
      .body {
        padding: 8px 6px;
        display: flex;
        flex-direction: column;
        gap: 0.6rem;
        align-items: start;
      }

      .label {
        display: inline-block;
        font-weight: bold;
        margin-right: 1ch;
      }
    `

  }

  static get properties() {
    return {
      label: { attribute: false },
      position: { attribute: false },
      consequence: { attribute: false }
    }
  }

  focusOnVariant = () => {
    const position = parseInt(this.position);
    const params = [{
      start_residue_number: position,
      end_residue_number: position,
    }];
    this.onVariantFocus(params);
  }

  render() {
    return html`
      <control-panel title="Variant">
        <div class="body">
          <div class="row">
            <span class="label">Label:</span>
            <span>${this.label}</span>
          </div>
          <div class="row">
            <span class="label">Protein position:</span>
            <span>${this.position}</span>
          </div>
          <div class="row">
            <span class="label">Consequence:</span>
            <span>${this.consequence}</span>
          </div>

          <button @click=${this.focusOnVariant}>
            Focus
          </button>
        </div>
      </control-panel>
    `;
  }

}

customElements.define('vep-variant-control-panel', VepVariantControlPanel);


/**
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
 */