import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

export class ExonsControlPanel extends LitElement {

  static get styles() {
    return css`
      :host {
        display: block;
        border: 1px solid #ccc;
      }

      .panel-title {
        background-color: var(--main-dark);
        color: white;
        font-weight: bold;
        padding: 4px;
      }

      .panel-summary {
        display: grid;
        grid-template-columns: 1fr auto auto auto;
        column-gap: 8px;
        align-items: center;
        font-weight: bold;
        padding: 8px 4px 8px 6px;
      }

      .exons-count {
        min-width: 10px;
        padding: 2px 6px;
        font-size: 10px;
        font-weight: bold;
        border: 1px solid var(--main-dark);
        text-align: center;
        border-radius: 10px;
      }

      .show-feature, .panel-content-toggle {
        width: 16px;
        height: 16px;
        border: none;
        outline: none;
        cursor: pointer;
      }

      .show-feature_hidden {
        background: url(/i/16/eye_no.png);
      }

      .show-feature_visible {
        background: url(/i/16/eye.png);
      }

      .toggle-expanded {
        background: url(/i/16/minus-button.png) no-repeat right center;
      }

      .toggle-collapsed {
        background: url(/i/16/plus-button.png) no-repeat right center;      
      }

      .exon-details-wrapper {
        padding: 5px 5px 5px 10px;
      }

      .exon-details {
        width: 100%;
        border: 1px solid #ccc;
      }

      .exon-details th {
        background-color: #ccc;
        padding: 4px;
      }

      .exon-details tbody tr td:nth-child(2),
      .exon-details tbody tr td:nth-child(3) {
        text-align: center;
      }

      .exon-row td:first-child {
        border-left-width: 5px;
        border-left-style: solid;
        padding-left: 6px;
      }
    `;
  }

  static get properties() {
    return {
      exons: { attribute: false },
      selectedExonIndices: { attribute: false },
      isExpanded: { state: true }
    }
  }

  areAllExonsVisible() {
    return this.selectedExonIndices.length === this.exons.length;
  }

  isExonVisible(exonIndex) {
    return this.selectedExonIndices.includes(exonIndex);
  }

  toggleSelectedExon(exonIndex) {
    if (this.selectedExonIndices.includes(exonIndex)) {
      const filteredIndices = this.selectedExonIndices.filter(index => index !== exonIndex);
      this.onExonSelectionChange(filteredIndices);
    } else {
      this.onExonSelectionChange([...this.selectedExonIndices, exonIndex]);
    }
  }

  toggleAllExons() {
    if (this.selectedExonIndices.length) {
      this.onExonSelectionChange([]);
    } else {
      const exonIndices = this.exons.map((_, index) => index);
      this.onExonSelectionChange(exonIndices);
    }
  }

  render() {
    return html`
      <div class="panel-title">
        Exons
      </div>
      <div class="panel-summary">
        Exons
        <span class="exons-count">${this.exons.length}</span>
        <button
          class="show-feature ${this.areAllExonsVisible() ? 'show-feature_visible' : 'show-feature_hidden'}"
          @click=${this.toggleAllExons.bind(this)}
        ></button>
        <button
          class="panel-content-toggle ${this.isExpanded ? 'toggle-expanded' : 'toggle-collapsed'}"
          @click=${() => this.isExpanded = !this.isExpanded}
        ></button>
      </div>
      ${
        this.isExpanded ? html`
          <div class="exon-details-wrapper">
            <table class="exon-details">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Location</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                ${this.exons.map((exon, index) => {
                  return this.renderExonRow(exon, index)
                })}
              </tbody>
            </table>
          </div>
        ` : null
      }
    `;
  }

  renderExonRow(exon, index) {
    return html`
      <tr class="exon-row">
        <td style="border-color: ${exon.color}">Exon ${index + 1}</td>
        <td>${exon.start}-${exon.end}</td>
        <td>
          <button
            class="show-feature ${this.isExonVisible(index) ? 'show-feature_visible' : 'show-feature_hidden'}"
            @click=${() => this.toggleSelectedExon(index)}
          ></button>
        </td>
      </tr>
    `;
  }

};


customElements.define('exons-control-panel', ExonsControlPanel);
