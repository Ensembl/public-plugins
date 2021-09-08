import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

export class ExonsControlPanel extends LitElement {

  static get styles() {
    return css`
      :host {
        display: block;
        height: 100px;
        // background: var(--main-v-dark);
        // color: white;
      }

      .exon-row td:first-child {
        border-left-width: 2px;
        border-left-style: solid;
      }
    `;
  }

  static get properties() {
    return {
      exons: { attribute: false }
    }
  }

  render() {
    return html`
      <div>
        <table>
        <tbody>
          ${this.exons.map((exon, index) => {
            return this.renderExonRow(exon, index)
          })}
        </tbody>
        </table>
      </div>
    `;
  }

  renderExonRow(exon, index) {
    return html`
      <tr class="exon-row">
        <td style="border-color: ${exon.color}">Exon ${index + 1}</td>
        <td>${exon.start}-${exon.end}</td>
        <td>
          <span>eye</span>
        </td>
      </tr>
    `;
  }

};


customElements.define('exons-control-panel', ExonsControlPanel);
