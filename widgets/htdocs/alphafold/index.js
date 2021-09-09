import { html, css, LitElement } from 'https://unpkg.com/lit@2.0.0-rc.4/index.js?module';

import { fetchAlphaFoldId, fetchExons, fetchVariants } from './dataFetchers.js';
import { getRGBFromHex } from './colorHelpers.js';

import './exonsControlPanel.js';
import './variantsControlPanel.js';

export class EnsemblAlphafoldViewer extends LitElement {

  static get styles() {
    return css`
      :host {
        display: block;
      }

      .container {
        display: grid;
        grid-template-columns: [molstar-canvas] 800px [controls] minmax(300px, max-content);
        grid-column-gap: 20px;
      }

      .molstar-canvas {
        grid-column: molstar-canvas;
        position: relative;
        width: 800px;
        height: 600px;
        margin-top: 96px; // <-- for the sequence element, which has an absolute position and is shifted to the top
      }

      .controls {
        grid-column: controls;
        display: flex;
        flex-direction: column;
        gap: 16px;
      }
    `;
  }

  static get properties() {
    return {
      exons: { state: true },
      variants: { state: true },
      selectedExonIndices: { state: true },
      selectedSiftIndices: { state: true },
      selectedPolyphenIndices: { state: true },
    }
  }

  constructor() {
    super();
    this.selectedExonIndices = [];
    this.selectedSiftIndices = [];
    this.selectedPolyphenIndices = [];
  }

  connectedCallback() {
    super.connectedCallback();
    this.fetchData().then((result) => {
      const { alphafoldId, exons, variants } = result;
      this.initializeMolstar(alphafoldId);
      this.exons = exons;
      this.variants = variants;
    });
  }

  updated(updatedProperties) {
    const relevantPropertyNames = [
      'selectedExonIndices'
    ];
    const updatedPropertyNames = [...updatedProperties.keys()];
    const isRelevantPropertyUpdated = relevantPropertyNames
      .some(name => updatedPropertyNames.includes(name));

    if (isRelevantPropertyUpdated && this.molstarInstance) {
      this.updateMolstarSelections();
    }
  }

  async fetchData() {
    const { restUrlRoot, enspId } = this.dataset;

    try {
      const alphafoldId = await fetchAlphaFoldId({ rootUrl: restUrlRoot, enspId });
      const exons = await fetchExons({ rootUrl: restUrlRoot, enspId });
      const variants = await fetchVariants({ rootUrl: restUrlRoot, enspId });

      return {
        alphafoldId,
        exons,
        variants
      }
    } catch (e) {
      console.log('data fetching error', e); // FIXME: show an error element
    }
  }

  /**
   * @param {string} afdbId - Identifier of the alphafold molecule.
   */
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
    
    const molstarContainer = this.shadowRoot.querySelector('.molstar-canvas');

    this.molstarInstance.render(molstarContainer, options);
  }

  updateMolstarSelections() {
    const exonSelections = this.selectedExonIndices
      .map((index) => this.exons[index])
      .map(exon => ({
        struct_asym_id: 'A',
        start_residue_number: exon.start,
        end_residue_number: exon.end,
        color: getRGBFromHex(exon.color)
      }));

    const selections = [
      ...exonSelections
    ];

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

  onVariantSelectionChange(type, selectedIndices) {
    // this.selectedExonIndices = selectedIndices;
  }

  render() {
    return html`
      <link rel="stylesheet" type="text/css" href="https://alphafold.ebi.ac.uk/assets/css/af-pdbe-molstar-light-1.1.1.css" />
      <div class="container">
        <div class="molstar-canvas"></div>
        <div class="controls">
          ${ this.exons && html`
            <exons-control-panel
              .exons=${this.exons}
              .selectedExonIndices=${this.selectedExonIndices}
              .onExonSelectionChange=${this.onExonSelectionChange.bind(this)}
            ></exons-control-panel>
          `}
          ${  this.variants && html`
            <variants-control-panel
              .variants=${this.variants}
              .selectedSiftIndices=${this.selectedExonIndices}
              .selectedPolyphenIndices=${this.selectedExonIndices}
              .onVariantSelectionChange=${this.onVariantSelectionChange.bind(this)}
            ></exons-control-panel>
          `}
        </div>
      </div>
    `;
  }
}

customElements.define('ensembl-alphafold-viewer', EnsemblAlphafoldViewer);
