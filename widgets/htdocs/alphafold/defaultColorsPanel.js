import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

import './controlPanel.js';

export class DefaultColorsPanel extends LitElement {

  static get styles() {
    return css`
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
    `;
  }

  render() {
    return html`
      <control-panel title="Model Confidence">
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
        </div>
      </control-panel>
    `;
  }
};


customElements.define('default-colors-panel', DefaultColorsPanel);
