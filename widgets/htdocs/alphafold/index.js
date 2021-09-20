import { html, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

import {
  fetchAlphaFoldId,
  fetchExons,
  fetchVariants,
  fetchProteinFeatures
} from './dataFetchers.js';
import { getRGBFromHex } from './colorHelpers.js';

import './exonsControlPanel.js';
import './variantsControlPanel.js';
import './defaultColorsPanel.js';
import './proteinFeaturesControlPanel.js';


/**
 * Note that this component cannot, as of now, use shadow DOM.
 *
 * This is because the pdbe-molstar version (1.1.1) loaded for this component
 * (see public-plugins/widgets/modules/EnsEMBL/Web/Document/Element/BodyJavascript.pm)
 * is using an older (v.1.1.1) version of Molstar, which in turn depends on an old version of React (earlier than v17).
 * Before React v.17, all React events had to bubble up to window.document to get registered,
 * whereas shadow DOM would prevent this.
 *
 * Since this component can't use shadow DOM, it can't define its own scoped styles.
 * CSS rules for this component are defined in 95_AFDB.css
 */

export class EnsemblAlphafoldViewer extends LitElement {

  static get properties() {
    return {
      loadCompleted: { state: true },
      exons: { state: true },
      variants: { state: true },
      proteinFeatures: { state: true },
      selectedExonIndices: { state: true },
      selectedSiftIndices: { state: true },
      selectedPolyphenIndices: { state: true },
      selectedProteinFeatureIndices: { state: true },
    }
  }

  constructor() {
    super();
    this.selectedExonIndices = [];
    this.selectedSiftIndices = [];
    this.selectedPolyphenIndices = [];
    this.selectedProteinFeatureIndices = {};
  }

  // prevent the component from rendering into the shadow DOM
  createRenderRoot() {
    return this;
  }

  connectedCallback() {
    super.connectedCallback();

    Promise.all([
      this.loadPdbeMolstarScript(),
      this.fetchData()
    ]).then(([, result]) => {
      const { alphafoldId, exons, variants, proteinFeatures } = result;
      this.initializeMolstar(alphafoldId);
      this.exons = exons;
      this.variants = variants;
      this.proteinFeatures = proteinFeatures;
      this.selectedProteinFeatureIndices = Object.keys(proteinFeatures)
        .reduce((obj, key) => {
          obj[key] = [];
          return obj;
        }, {});
    });
  }

  updated(updatedProperties) {
    const relevantPropertyNames = [
      'selectedExonIndices',
      'selectedSiftIndices',
      'selectedPolyphenIndices',
      'selectedProteinFeatureIndices'
    ];
    const updatedPropertyNames = [...updatedProperties.keys()];
    const isRelevantPropertyUpdated = relevantPropertyNames
      .some(name => updatedPropertyNames.includes(name));

    if (isRelevantPropertyUpdated && this.loadCompleted) {
      this.updateMolstarSelections();
    }
  }

  loadPdbeMolstarScript() {
    return new Promise((resolve) => {
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = 'https://alphafold.ebi.ac.uk/assets/js/af-pdbe-molstar-plugin-1.1.1.js';
      script.onload = resolve;
      document.head.appendChild(script);
    });
  }

  async fetchData() {
    const { restUrlRoot, enspId } = this.dataset;

    try {
      const alphafoldId = await fetchAlphaFoldId({ rootUrl: restUrlRoot, enspId });
      const exons = await fetchExons({ rootUrl: restUrlRoot, enspId });
      const variants = await fetchVariants({ rootUrl: restUrlRoot, enspId });
      const proteinFeatures = await fetchProteinFeatures({ rootUrl: restUrlRoot, enspId });

      return {
        alphafoldId,
        exons,
        variants,
        proteinFeatures
      }
    } catch (e) {
      console.log('data fetching error', e); // FIXME: show an error element
    }
  }

  initializeMolstar(afdbId) {
    this.molstarInstance = new PDBeMolstarPlugin();

    const options = {
      customData: {
        url: `https://alphafold.ebi.ac.uk/files/${afdbId}-model_v1.cif`,
        format: 'cif'
      },
      bgColor: { r: 255, g: 255, b: 255 },
      isAfView: true,
      hideCanvasControls: ['selection', 'animation', 'controlToggle', 'controlInfo']
    };
    
    const molstarContainer = this.querySelector('.molstar-canvas'); // if this component gets refactored to use shadow DOM, switch this.querySelector to this.shadowRoot.querySelector

    this.molstarInstance.render(molstarContainer, options);

    this.molstarInstance.events.loadComplete.subscribe(this.onLoadComplete.bind(this));
  }

  onLoadComplete() {
    this.loadCompleted = true;
    const loadCompleteEvent = new Event('loaded');
    this.dispatchEvent(loadCompleteEvent);
  }

  updateMolstarSelections() {
    const selectedExons = this.selectedExonIndices.map(index => this.exons[index]);
    const selectedSiftVariants = this.selectedSiftIndices.map(index => this.variants.sift[index]);
    const selectedPolyphenVariants = this.selectedPolyphenIndices.map(index => this.variants.polyphen[index]);
    const selectedProteinFeatures = Object.entries(this.selectedProteinFeatureIndices)
      .flatMap(([key, indices]) => indices.map(index => this.proteinFeatures[key][index]));

    const selections = [
      ...selectedExons,
      ...selectedProteinFeatures,
      ...selectedSiftVariants,
      ...selectedPolyphenVariants
    ].map(item => ({
      start_residue_number: item.start,
      end_residue_number: item.end,
      color: getRGBFromHex(item.color)
    }));

    if (selections.length) {
      this.molstarInstance.visual.select({
        data: selections,
        nonSelectedColor: { r: 255, g: 255, b: 255 }
      });
    } else {
      this.molstarInstance.visual.clearSelection();
    }
  }

  onExonSelectionChange(selectedIndices) {
    this.selectedExonIndices = selectedIndices;
  }

  onVariantSelectionChange({ type, selectedIndices }) {
    if (type === 'sift') {
      this.selectedSiftIndices = selectedIndices;
    } else {
      this.selectedPolyphenIndices = selectedIndices;
    }
  }

  onProteinFeatureSelectionChange(selectedIndices) {
    this.selectedProteinFeatureIndices = selectedIndices;
  }

  render() {
    return html`
      <link rel="stylesheet" type="text/css" href="https://alphafold.ebi.ac.uk/assets/css/af-pdbe-molstar-light-1.1.1.css" />
      <div class="container">
        <div class="molstar-canvas"></div>
        <div class="controls">
          ${this.renderControlPanels()}
        </div>
      </div>
    `;
  }

  renderControlPanels() {
    if (!this.loadCompleted) {
      return null;
    }

    return html`
      ${ this.exons && html`
        <exons-control-panel
          .exons=${this.exons}
          .selectedExonIndices=${this.selectedExonIndices}
          .onExonSelectionChange=${this.onExonSelectionChange.bind(this)}
        ></exons-control-panel>
      `}
      ${
        this.proteinFeatures && html`
          <protein-features-control-panel
            .proteinFeatures=${this.proteinFeatures}
            .selectedIndices=${this.selectedProteinFeatureIndices}
            .onSelectionChange=${this.onProteinFeatureSelectionChange.bind(this)}
          ></protein-features-control-panel>
        `
      }
      ${ this.variants && html`
        <variants-control-panel
          .species=${this.dataset.species}
          .variants=${this.variants}
          .selectedSiftIndices=${this.selectedSiftIndices}
          .selectedPolyphenIndices=${this.selectedPolyphenIndices}
          .onVariantSelectionChange=${this.onVariantSelectionChange.bind(this)}
        ></exons-control-panel>
      `}
      <default-colors-panel></default-colors-panel>
    `;
  }
}

customElements.define('ensembl-alphafold-viewer', EnsemblAlphafoldViewer);
