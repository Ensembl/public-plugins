import { html, css, LitElement } from 'https://unpkg.com/lit@2.2.5/index.js?module';

import './controlPanel.js';

export class DefaultColorsPanel extends LitElement {

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

      .dark-blue {
        background-color: rgb(0, 83, 214);
      }

      .light-blue {
        background-color: rgb(101, 203, 243);
      }

      .yellow {
        background-color: rgb(255, 219, 19);
      }

      .orange {
        background-color: rgb(255, 125, 69);
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
        <span>Model confidence</span>
        ${
          this.onVisibilityToggle ? this.renderVisibilityToggle() : null
        }
      </div>
      <div class="body">
        <div class="row">
          <span class="color-sample dark-blue"></span>
          <span class="label">Very high (pLDDT > 90)</span>
        </div>
        <div class="row">
          <span class="color-sample light-blue"></span>
          <span class="label">Confident (90 > pLDDT > 70)</span>
        </div>
        <div class="row">
          <span class="color-sample yellow"></span>
          <span class="label">Low (70 > pLDDT > 50)</span>
        </div>
        <div class="row">
          <span class="color-sample orange"></span>
          <span class="label">Very low (pLDDT < 50)</span>
        </div>
        <div class="explainer">
          AlphaFold produces a per-residue confidence score (pLDDT)
          between 0 and 100. Some regions below 50 pLDDT
          may be unstructured in isolation.
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


customElements.define('default-colors-panel', DefaultColorsPanel);
