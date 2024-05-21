
import { html, css, LitElement } from 'https://unpkg.com/lit@2.2.5/index.js?module';

import './controlPanel.js';


export class MissenseColorsPanel extends LitElement {

  static get styles() {

    return css`
      :host {
        display: block;
        border: 1px solid #ccc;
        min-width: max-content;
      }

      .panel-title {
        display: flex;
        align-items: center;
        justify-content: space-between;
        background-color: var(--main-dark);
        color: white;
        font-weight: bold;
        padding: 4px 28px 4px 4px;
      }

      .body {
        padding: 8px 6px;
      }

      .row {
        display: flex;
        align-items: center;
      }

      .row:not(:last-child) {
        margin-bottom: 16px;
      }

      .color-sample {
        width: 20px;
        height: 20px;
        margin-right: 1ch;
      }
      
      .min {
        background-color: #3753A1;
      }
      
      .center {
        background-color: #A9A8A8;
      }
      
      .max {
        background-color: #A60B14;
      }

      .explainer {
        margin-top: 1rem;
        width: 40ch;
        line-height: 1.5;
      }

      .show-feature {
        width: 16px;
        height: 16px;
        border: none;
        outline: none;
        cursor: pointer;
        filter: brightness(0) invert(1);
      }

      .show-feature_hidden {
        background: url(/i/16/eye_no.png);
      }

      .show-feature_visible {
        background: url(/i/16/eye.png);
      }
    `;
  }

  static get properties() {
    return {
      visible: { attribute: false }
    }
  }

  constructor() {
    super();
    this.visible = true;
  }

  render() {
    return html`
      <div class="panel-title">
        <span>AlphaMissense Pathogenicity</span>
        ${
          this.onVisibilityToggle ? this.renderVisibilityToggle() : null
        }
      </div>
      <div class="body">
        <div class="row">
          <span class="color-sample max"></span>
          <span class="label">Pathogenic</span>
        </div>
        <div class="row">
          <span class="color-sample center"></span>
          <span class="label">Uncertain</span>
        </div>
        <div class="row">
          <span class="color-sample min"></span>
          <span class="label">Benign</span>
        </div>
        <div class="explainer">
          The displayed color for each residue is the average AlphaMissense pathogenicity 
          score across all possible amino acid substitutions at that position
        </div>
      </div>
    `;
  }

  renderVisibilityToggle() {
    const classes = this.visible
      ? 'show-feature show-feature_visible'
      : 'show-feature show-feature_hidden'

    return html`
      <button
        class=${classes}
        @click=${this.onVisibilityToggle}
      ></button>
    `;
  }
};

customElements.define('missense-colors-panel', MissenseColorsPanel);