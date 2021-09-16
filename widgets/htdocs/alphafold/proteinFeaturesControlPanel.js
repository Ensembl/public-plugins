import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

export class ProteinFeaturesControlPanel extends LitElement {

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

      .section-summary {
        display: grid;
        grid-template-columns: 1fr auto auto auto;
        column-gap: 8px;
        align-items: center;
        font-weight: bold;
        padding: 8px 4px 8px 6px;
      }

      .features-count {
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

    `;
  }

  static get properties() {
    return {
      proteinFeatures: { attribute: false },
      selectedIndices: { attribute: false },
      expandedSections: { state: true }
    }
  }

  willUpdate(updatedProperties) {
    console.log('in willUpdate');
    if (updatedProperties.has('proteinFeatures') && !this.expandedSections) {
      this.expandedSections = Object.keys(this.proteinFeatures)
        .reduce((obj, key) => {
          obj[key] = false;
          return obj;
        }, {});
    }
  }

  areAllFeaturesVisible(type) {
    const selectedIndices = this.selectedIndices[type];
    const features = this.proteinFeatures[type];
    return selectedIndices.length === features.length;
  }

  isFeatureVisible(type, index) {
    const selectedIndices = this.selectedIndices[type];
    return selectedIndices.includes(index);
  }

  toggleAllFeatures(featureType) {
    console.log('will toggle all features');
  }

  toggleFeature(featureType, index) {
    console.log('will toggle feature');
  }

  render() {
    return html`
      <div class="panel-title">
        Protein features
      </div>
      ${ this.renderSections() }
    `;
  }

  renderSections() {
    if (!this.proteinFeatures) {
      return null;
    }

    return proteinFeatureTypes
      .filter(type => type in this.proteinFeatures)
      .map(type => this.renderSection(type))
  }

  renderSection(featureType) {
    const features = this.proteinFeatures[featureType];

    return html`
      <div class="section">
        <div class="section-summary">
          <span class="section-title">
            ${featureType}
          </span>
          <span class="features-count">
            ${features.length}
          </span>
          <button
            class="show-feature ${this.areAllFeaturesVisible(featureType) ? 'show-feature_visible' : 'show-feature_hidden'}"
            @click=${() => this.toggleAllFeatures(featureType)}
          ></button>
          <button
            class="panel-content-toggle ${this.expandedSections[featureType] ? 'toggle-expanded' : 'toggle-collapsed'}"
            @click=${() => {
              this.expandedSections = {
                ...this.expandedSections,
                [featureType]: !this.expandedSections[featureType]
              }
            }}
          ></button>
        </div>
        ${ this.expandedSections[featureType] ? this.renderProteinFeatures(featureType) : null }
      </div>
    `;
  }

  renderProteinFeatures(featureType) {
    const features = this.proteinFeatures[featureType];

    return html`
      <div class="features-wrapper">
        <table class="protein-features">
          <thead>
            <tr>
              <th>ID</th>
              <th>Location</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            ${features.map((feature, index) => {
              return this.renderFeatureRow({
                feature,
                index,
                type: featureType,
                isVisible: false
              })
            })}
          </tbody>
        </table>
      </div>
    `;
  }

  renderFeatureRow({ feature, index, type, isVisible }) {
    return html`
      <tr class="feature-row">
        <td style="border-color: ${feature.color}">${feature.id}</td>
        <td>${feature.start}-${feature.end}</td>
        <td>
          <button
            class="show-feature ${isVisible ? 'show-feature_visible' : 'show-feature_hidden'}"
            @click=${() => this.toggleFeature(type, index)}
          ></button>
        </td>
      </tr>
    `;
  }

}

customElements.define('protein-features-control-panel', ProteinFeaturesControlPanel);


const featureTypeToUrlPatternMap = new Map([
  [ 'Gene3D', 'http://gene3d.biochem.ucl.ac.uk/Gene3D/search?mode=protein&sterm=' ],
  [ 'PANTHER', 'http://www.pantherdb.org/panther/family.do?clsAccession=' ],
  [ 'Pfam', 'https://pfam.xfam.org/family/' ],
  [ 'Smart', 'http://smart.embl-heidelberg.de/smart/do_annotation.pl?DOMAIN=' ],
  [ 'PRINTS', 'https://www.ebi.ac.uk/interpro/signature/' ],
]);

export const proteinFeatureTypes = [ ...featureTypeToUrlPatternMap.keys() ];
export const proteinFeatureTypesSet = new Set(proteinFeatureTypes);
