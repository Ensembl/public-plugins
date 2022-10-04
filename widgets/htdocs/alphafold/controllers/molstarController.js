import { getRGBFromHex } from '../colorHelpers.js';
import { MissingAlphafoldModelError } from '../dataFetchers.js';

export class MolstarController {

  constructor(host) {
    this.host = host;
    this.host.addController(this);

    this.loadScript = this.loadScript.bind(this);
    this.renderAlphafoldStructure = this.renderAlphafoldStructure.bind(this);
    this.updateSelections = this.updateSelections.bind(this);
    this.focus = this.focus.bind(this);
  }

  async loadScript() {
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.src= 'https://www.ebi.ac.uk/pdbe/pdb-component-library/js/pdbe-molstar-plugin-3.0.0.js';
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
    this.molstarInstance = new PDBeMolstarPlugin();
  }

  // Alphafold ids are formatted as AF-<uniprot_id>-F1
  // We need the uniprot id to talk to AF apis
  getModelFileUrl = async (alphafoldId) => {
    const alphafoldPredictionEndpoint = 'https://alphafold.ebi.ac.uk/api/prediction';
    const parsingRegex = /-(.+)-/;
    const uniprotId = alphafoldId.match(parsingRegex)[1];
    const url = `${alphafoldPredictionEndpoint}/${uniprotId}`;

    const alphafoldPredictionEntriesResponse = await fetch(url);
    if (alphafoldPredictionEntriesResponse.status === 404) {
      // no alphafold model files found
      throw new MissingAlphafoldModelError();
    } else if (!alphafoldPredictionEntriesResponse.ok) {
      throw new Error('Something wrong with Alphafold prediction api');
    }

    // alphafold's api will respond with an array of entries; we are interested in the first one
    const alphafoldEntry = alphafoldPredictionEntries[0];
    return alphafoldEntry.cifUrl;
  }

  async renderAlphafoldStructure({ moleculeId, canvasContainer }) {
    const modelFileUrl = await this.getModelFileUrl(moleculeId);

    const options = {
      customData: {
        url: modelFileUrl,
        format: 'cif'
      },
      bgColor: { r: 255, g: 255, b: 255 },
      alphafoldView: true,
      hideCanvasControls: ['selection', 'animation', 'controlToggle', 'controlInfo'],
      subscribeEvents: console.l
    };

    this.molstarInstance.render(canvasContainer, options);

    return new Promise(resolve => {
      this.molstarInstance.events.loadComplete.subscribe(resolve);
    });

  }

  updateSelections({ selections, showConfidence = false }) {
    selections = selections.map(item => ({
      start_residue_number: item.start,
      end_residue_number: item.end,
      color: getRGBFromHex(item.color)
    }));

    const params = {
      data: selections
    };

    if (!showConfidence) {
      params.nonSelectedColor = { r: 255, g: 255, b: 255 }; // color the rest of the molecule white
    }

    this.molstarInstance.visual.select(params);
  }

  focus(params) {
    this.molstarInstance.visual.focus(params);
  }

};
