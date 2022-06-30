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

      .row {
        display: flex;
        align-items: center;
      }

      .color-label {
        width: 20px;
        height: 20px;
        margin-right: 1ch;
        background-color: rgb(247, 22, 255);
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
            <span class="color-label"></span>
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
