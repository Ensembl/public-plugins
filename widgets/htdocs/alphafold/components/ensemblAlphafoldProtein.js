import { html, LitElement } from 'https://unpkg.com/lit@2.2.5/index.js?module';

import { MolstarController } from '../controllers/molstarController.js';
import { ExonsController } from '../controllers/exonsController.js';
import { ProteinFeaturesController } from '../controllers/proteinFeaturesController.js';
import { VariantsController } from '../controllers/variantsController.js';

import {
  fetchAlphaFoldId,
  MissingAlphafoldModelError
} from '../dataFetchers.js';

import './exonsControlPanel.js';
import './variantsControlPanel.js';
import './defaultColorsPanel.js';
import './proteinFeaturesControlPanel.js';


const alphafoldEbiRootUrl = 'https://alphafold.ebi.ac.uk';

export class EnsemblAlphafoldProtein extends LitElement {

  static get properties() {
    return {
      loadCompleted: { state: true }
    }
  }

  constructor() {
    super();
    console.log('constructor', this.dataset);

    this.molstarController = new MolstarController(this);
    this.exonsController = new ExonsController(this);
    this.proteinFeaturesController = new ProteinFeaturesController(this);
    this.variantsController = new VariantsController(this);
  }

  // prevent the component from rendering into the shadow DOM, see README.md for explanation
  createRenderRoot() {
    return this;
  }

  firstUpdated() {
    const { restUrlRoot, enspId } = this.dataset;
    // if this component gets refactored to use shadow DOM, switch this.querySelector to this.shadowRoot.querySelector
    const molstarContainer = this.querySelector('.molstar-canvas');

    Promise.all([
      fetchAlphaFoldId({ rootUrl: restUrlRoot, enspId }),
      this.molstarController.loadScript(alphafoldEbiRootUrl),
      this.exonsController.load({ rootUrl: restUrlRoot, enspId }),
      this.proteinFeaturesController.load({ rootUrl: restUrlRoot, enspId }),
      this.variantsController.load({ rootUrl: restUrlRoot, enspId })
    ]).then(([alphafoldId]) => {
      return this.molstarController.renderAlphafoldStructure({
        moleculeId: alphafoldId,
        urlRoot: alphafoldEbiRootUrl,
        canvasContainer: molstarContainer
      });
    }).then(() => {
      this.onLoadComplete();
    }).catch(error => {
      this.onLoadFailed(error);
    });
  }

  updated() {
    if (!this.loadCompleted) {
      return;
    }
    const selections = [
      this.exonsController.getSelectedExons(),
      this.proteinFeaturesController.getSelectedFeatures(),
      this.variantsController.getSelectedSiftVariants(),
      this.variantsController.getSelectedPolyphenVariants()
    ].flat();

    this.molstarController.updateSelections(selections);
  }

  onLoadComplete() {
    this.loadCompleted = true;
    const loadCompleteEvent = new Event('loaded');
    this.dispatchEvent(loadCompleteEvent);
  }

  // will be called if either pdbe-molstar failed to load or one of the REST endpoints failed to respond
  onLoadFailed(error) {
    if (error instanceof MissingAlphafoldModelError) {
      this.dispatchEvent(new Event('alphafold-model-missing'));
    } else {
      this.dispatchEvent(new Event('load-error'));
    }
  }

  render() {
    return html`
      <link rel="stylesheet" type="text/css" href="${alphafoldEbiRootUrl}/assets/css/af-pdbe-molstar-light-1.1.1.css" />
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
      ${ this.exonsController.exons && html`
        <exons-control-panel
          .exons=${this.exonsController.exons}
          .selectedExonIndices=${this.exonsController.getSelectedIndices()}
          .onExonSelectionChange=${this.exonsController.onSelectionChange}
        ></exons-control-panel>
      `}
      ${
        this.proteinFeaturesController.proteinFeatures && html`
          <protein-features-control-panel
            .proteinFeatures=${this.proteinFeaturesController.proteinFeatures}
            .selectedIndices=${this.proteinFeaturesController.getSelectedIndices()}
            .onSelectionChange=${this.proteinFeaturesController.onSelectionChange}
          ></protein-features-control-panel>
        `
      }
      ${ this.variantsController.variants && html`
        <variants-control-panel
          .species=${this.dataset.species}
          .variants=${this.variantsController.variants}
          .selectedSiftIndices=${this.variantsController.getSelectedSiftIndices()}
          .selectedPolyphenIndices=${this.variantsController.getSelectedPolyphenIndices()}
          .onVariantSelectionChange=${this.variantsController.onSelectionChange}
        ></variants-control-panel>
      `}
      <default-colors-panel></default-colors-panel>
    `;
  }
}

customElements.define('ensembl-alphafold-protein', EnsemblAlphafoldProtein);
