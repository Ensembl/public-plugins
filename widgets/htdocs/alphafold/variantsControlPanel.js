import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

import './controlPanel.js';

export class VariantsControlPanel extends LitElement {

  static get styles() {
    return css`
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
        padding: 4px;
      }

      .variant-details tbody tr td:nth-child(2),
      .variant-details tbody tr td:nth-child(3) {
        text-align: center;
      }

      .variant-row td:first-child {
        border-left-width: 5px;
        border-left-style: solid;
        padding-left: 6px;
      }

      .variant-score {
        display: block;
        width: 4ch;
        margin: auto;
        text-align: center;
        font-weight: bold;
        padding: 1px 2px 0 2px;
        border-width: 1px;
        border-style: solid;
        border-radius: 6px;
      }

      .group-toggles-wrapper {
        padding-left: 10px;
      }

      .group-toggle {
        display: inline-flex;
        border: 1px solid #ccc;
        border-radius: 6px;
        overflow: hidden;
      }

      .group-toggle:not(:last-child) {
        margin-right: 1ch;
      }

      .group-toggle .show-feature {
        margin: 2px 4px;
      }

      .group-toggle__label {
        display: flex;
        align-items: center;
        padding: 0 4px;
        color: white;
      }

      .group-toggle__label_good {
        background: green;
      }

      .group-toggle__label_bad {
        background: red;
      }

      a {
        text-decoration:none;
        color: var(--link-color);
      }

      a:visited {
        color: var(--link-visited-color);
      }

      a:hover {
        color: var(--link-hover-color);
      }

      a:active {
        color: var(--link-hover-color);
      }
    `;
  }

  static get properties() {
    return {
      species: { attribute: false },
      variants: { attribute: false },
      selectedSiftIndices: { attribute: false },
      selectedPolyphenIndices: { attribute: false },
      areSiftsExpanded: { state: true },
      arePolyphensExpanded: { state: true }
    }
  }

  areAllSiftsVisible() {
    return this.selectedSiftIndices.length === this.variants.sift.length;
  }

  areAllPolyphensVisible() {
    return false;
  }

  toggleAllSifts() {
    if (this.selectedSiftIndices.length) {
      this.onVariantSelectionChange({ type: 'sift', selectedIndices: [] });
    } else {
      const variantIndices = this.variants.sift.map((_, index) => index);
      this.onVariantSelectionChange({ type: 'sift', selectedIndices: variantIndices });
    }
  }

  toggleSiftsCategory({ category, visible }) {

  }

  toggleAllPolyphens() {
    if (this.selectedExonIndices.length) {
      this.onExonSelectionChange([]);
    } else {
      const exonIndices = this.exons.map((_, index) => index);
      this.onExonSelectionChange(exonIndices);
    }
  }

  toggleSelectedVariant(type, variantIndex) {
    const variantIndices = type === 'sift'
      ? this.selectedSiftIndices
      : this.selectedPolyphenIndices;

    if (variantIndices.includes(variantIndex)) {
      const filteredIndices = variantIndices.filter(index => index !== variantIndex);
      this.onVariantSelectionChange({ type, selectedIndices: filteredIndices });
    } else {
      this.onVariantSelectionChange({ type, selectedIndices: variantIndices.concat(variantIndex) });
    }
  }

  render() {
    return html`
      <control-panel title="Variants">
        ${ this.renderSifts() }
        ${ this.renderPolyphens() }
      </control-panel>
    `;
  }

  renderSifts() {
    if (!this.variants.sift.length) {
      return null;
    }
    const selectedIndicesSet = new Set(this.selectedSiftIndices);

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
          <div class="group-toggles-wrapper">
            ${this.renderSiftsGoodToggle()}
            ${this.renderSiftsBadToggle()}
          </div>
          <div class="variant-details-wrapper">
            <table class="variant-details">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Location</th>
                  <th>Residues</th>
                  <th>Score</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                ${this.variants.sift.map((variant, index) => {
                  return this.renderVariantRow({
                    variant,
                    index,
                    type: 'sift',
                    isVisible: selectedIndicesSet.has(index)
                  })
                })}
              </tbody>
            </table>
          </div>
        ` : null
      }
    `;
  }

  renderSiftsGoodToggle() {
    const goodVariants = this.variants.sift.filter(variant => variant.sift_class === 'score_good');

    if (!goodVariants.length) {
      return null;
    }

    const goodVariantIdsSet = new Set(goodVariants.map(variant => variant.id));

    const goodVariantIndices = this.variants.sift
      .map((variant, index) => [variant, index])
      .filter(([ variant ]) => goodVariantIdsSet.has(variant.id))
      .map(([, index]) => index);
    const currentSelectedIndicesSet = new Set(this.selectedSiftIndices);

    const areOnlyGoodVariantsVisible = goodVariantIndices.length === currentSelectedIndicesSet.size
      && goodVariantIndices.every((index) => currentSelectedIndicesSet.has(index));

    const onToggle = () => {
      if (areOnlyGoodVariantsVisible) {
        this.onVariantSelectionChange({ type: 'sift', selectedIndices: [] });
      } else {
        this.onVariantSelectionChange({ type: 'sift', selectedIndices: goodVariantIndices });
      }
    }

    return html`
      <div class="group-toggle">
        <div class="group-toggle__label group-toggle__label_good">
          Tolerated
        </div>
        <button
          class="show-feature ${areOnlyGoodVariantsVisible ? 'show-feature_visible' : 'show-feature_hidden'}"
          @click=${onToggle}
        ></button>
      </div>
    `;
  }

  renderSiftsBadToggle() {
    const badVariants = this.variants.sift.filter(variant => variant.sift_class === 'score_bad');

    if (!badVariants.length) {
      return null;
    }

    const badVariantIdsSet = new Set(badVariants.map(variant => variant.id));

    const badVariantIndices = this.variants.sift
      .map((variant, index) => [variant, index])
      .filter(([ variant ]) => badVariantIdsSet.has(variant.id))
      .map(([, index]) => index);
    const currentSelectedIndicesSet = new Set(this.selectedSiftIndices);

    const areOnlyBadVariantsVisible = badVariantIndices.length === currentSelectedIndicesSet.size
      && badVariantIndices.every((index) => currentSelectedIndicesSet.has(index));

    const onToggle = () => {
      if (areOnlyBadVariantsVisible) {
        this.onVariantSelectionChange({ type: 'sift', selectedIndices: [] });
      } else {
        this.onVariantSelectionChange({ type: 'sift', selectedIndices: badVariantIndices });
      }
    }

    return html`
      <div class="group-toggle">
        <div class="group-toggle__label group-toggle__label_bad">
          Deleterious
        </div>
        <button
          class="show-feature ${areOnlyBadVariantsVisible ? 'show-feature_visible' : 'show-feature_hidden'}"
          @click=${onToggle}
        ></button>
      </div>
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
                  <th>Residues</th>
                  <th>Score</th>
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

  renderVariantRow({ variant, index, type, isVisible }) {
    return html`
      <tr class="variant-row">
        <td style="border-color: ${variant.color}">
          <a href="/${this.species}/Variation/Explore?v=${variant.id}" target="_blank">
            ${variant.id}
          </a>
        </td>
        <td>
          ${variant.start === variant.end
              ? variant.start :
              `${variant.start}-${variant.end}`
          }
        </td>
        <td>${variant.residues}</td>
        <td>
          <span class="variant-score" style="border-color: ${variant.color}; color: ${variant.color}">
            ${variant[type]}
          </span>
        </td>
        <td>
          <button
            class="show-feature ${isVisible ? 'show-feature_visible' : 'show-feature_hidden'}"
            @click=${() => this.toggleSelectedVariant(type, index)}
          ></button>
        </td>
      </tr>
    `;
  }

};


customElements.define('variants-control-panel', VariantsControlPanel);
