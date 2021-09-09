import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

export class VariantsControlPanel extends LitElement {

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

      .variants-count {
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

      .variant-details-wrapper {
        padding: 5px 5px 5px 10px;
      }

      .variant-details {
        width: 100%;
        border: 1px solid #ccc;
      }

      .variant-details th {
        background-color: #ccc;
      }

      .variant-details tbody tr td:nth-child(2),
      .variant-details tbody tr td:nth-child(3) {
        text-align: center;
      }

      .variant-row td:first-child {
        border-left-width: 5px;
        border-left-style: solid;
      }
    `;
  }

  static get properties() {
    return {
      variants: { attribute: false },
      selectedSiftIndices: { attribute: false },
      selectedPolyphenIndices: { attribute: false },
      areSiftsExpanded: { state: true },
      arePolyphensExpanded: { state: true }
    }
  }

  areAllSiftsVisible() {
    return false;
    // return this.selectedExonIndices.length === this.exons.length;
  }

  areAllPolyphensVisible() {
    return false;
  }

  isVariantVisible(type, variantIndex) {
    return false;
    // return this.selectedExonIndices.includes(exonIndex);
  }

  toggleAllSifts() {
    if (this.selectedExonIndices.length) {
      this.onExonSelectionChange([]);
    } else {
      const exonIndices = this.exons.map((_, index) => index);
      this.onExonSelectionChange(exonIndices);
    }
  }

  toggleAllPolyphens() {
    if (this.selectedExonIndices.length) {
      this.onExonSelectionChange([]);
    } else {
      const exonIndices = this.exons.map((_, index) => index);
      this.onExonSelectionChange(exonIndices);
    }
  }

  toggleSelectedVariant(type, index) {
    if (this.selectedExonIndices.includes(exonIndex)) {
      const filteredIndices = this.selectedExonIndices.filter(index => index !== exonIndex);
      this.onExonSelectionChange(filteredIndices);
    } else {
      this.onExonSelectionChange([...this.selectedExonIndices, exonIndex]);
    }
  }

  render() {
    return html`
      <div class="panel-title">
        Variants
      </div>
      ${ this.renderSifts() }
      ${ this.renderPolyphens() }
    `;
  }

  renderSifts() {
    if (!this.variants.sift.length) {
      return null;
    }

    return html`
      <div class="panel-summary">
        SIFT
        <span class="variants-count">${this.variants.sift.length}</span>
        <button
          class="show-feature ${this.areAllSiftsVisible() ? 'show-feature_visible' : 'show-feature_hidden'}"
          @click=${this.toggleAllSifts.bind(this)}
        ></button>
        <button
          class="panel-content-toggle ${this.areSiftsExpanded ? 'toggle-expanded' : 'toggle-collapsed'}"
          @click=${() => this.areSiftsExpanded = !this.areSiftsExpanded}
        ></button>
      </div>

      ${
        this.areSiftsExpanded ? html`
          <div class="variant-details-wrapper">
            <table class="variant-details">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Location</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                ${this.variants.sift.map((variant, index) => {
                  return this.renderVariantRow(variant, index, 'sift')
                })}
              </tbody>
            </table>
          </div>
        ` : null
      }
    `;
  }

  renderPolyphens() {
    if (!this.variants.polyphen.length) {
      return null;
    }

    return html`
      <div class="panel-summary">
        PolyPhen
        <span class="variants-count">${this.variants.polyphen.length}</span>
        <button
          class="show-feature ${this.areAllPolyphensVisible() ? 'show-feature_visible' : 'show-feature_hidden'}"
          @click=${this.toggleAllPolyphens.bind(this)}
        ></button>
        <button
          class="panel-content-toggle ${this.areSiftsExpanded ? 'toggle-expanded' : 'toggle-collapsed'}"
          @click=${() => this.arePolyphensExpanded = !this.arePolyphensExpanded}
        ></button>
      </div>

      ${
        this.arePolyphensExpanded ? html`
          <div class="variant-details-wrapper">
            <table class="variant-details">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Location</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                ${this.variants.polyphen.map((variant, index) => {
                  return this.renderVariantRow(variant, index, 'polyphen')
                })}
              </tbody>
            </table>
          </div>
        ` : null
      }
    `;
  }

  renderVariantRow(variant, index, type) {
    return html`
      <tr class="variant-row">
        <td style="border-color: ${variant.color}">${variant.id}</td>
        <td>${variant.start}-${variant.end}</td>
        <td>
          <button
            class="show-feature ${this.isVariantVisible(type, index) ? 'show-feature_visible' : 'show-feature_hidden'}"
            @click=${() => this.toggleSelectedVariant(type, index)}
          ></button>
        </td>
      </tr>
    `;
  }

};


customElements.define('variants-control-panel', VariantsControlPanel);
