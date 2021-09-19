import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

export class ControlPanel extends LitElement {

  static get styles() {
    return css`
      :host {
        display: block;
        border: 1px solid #ccc;
        min-width: max-content;
      }

      .panel-title {
        background-color: var(--main-dark);
        color: white;
        font-weight: bold;
        padding: 4px;
      }
    `;
  }

  static get properties() {
    return {
      title: { type: String }
    }
  }

  render() {
    return html`
      <div class="panel-title">
        ${this.title}
      </div>
      <slot></slot>
    `;
  }
};

customElements.define('control-panel', ControlPanel);
