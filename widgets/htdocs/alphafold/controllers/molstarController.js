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
    this.missenseUrl = null; // set during load

  }

  async loadScript() {
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.type = 'text/javascript';
      //script.src= 'https://www.ebi.ac.uk/pdbe/pdb-component-library/js/pdbe-molstar-plugin-3.0.0.js';
      script.src = 'https://cdn.jsdelivr.net/npm/pdbe-molstar@3.2.0/build/pdbe-molstar-plugin.js'
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
    this.molstarInstance = new PDBeMolstarPlugin();
  }
  
  // Alphafold ids are formatted as AF-<uniprot_id>-F1
  // We need the uniprot id to talk to AF apis
  getModelFileAndAnnotationUrl = async (alphafoldId) => {
    
    const alphafoldPredictionEndpoint = 'https://alphafold.ebi.ac.uk/api/prediction';
    const parsingRegex = /-(.+)-/;
    const uniprotId = alphafoldId[0].match(parsingRegex)[1];
    const url = `${alphafoldPredictionEndpoint}/${uniprotId}`;

    const alphafoldPredictionEntriesResponse = await fetch(url);
    if (alphafoldPredictionEntriesResponse.status === 404) {
      // no alphafold model files found
      throw new MissingAlphafoldModelError();
    } else if (!alphafoldPredictionEntriesResponse.ok) {
      throw new Error('Something wrong with Alphafold prediction api');
    }
    const alphafoldPredictionEntries = await alphafoldPredictionEntriesResponse.json();

    // alphafold's api will respond with an array of entries; we are interested in the first one
    const alphafoldEntry = alphafoldPredictionEntries[0];
    return {
      cif:alphafoldEntry.cifUrl,
      annotation:alphafoldEntry.amAnnotationsUrl
    };
  }

  async renderAlphafoldStructure({ modelFileUrl, canvasContainer }) {
    const options = {
      customData: {
        url: modelFileUrl,
        format: 'cif'
      },
      bgColor: { r: 255, g: 255, b: 255 },
      alphafoldView: true,
      sequencePanel:true,
      hideCanvasControls: ['selection', 'animation', 'controlToggle', 'controlInfo'],
      subscribeEvents: console.l
    };

    this.molstarInstance.render(canvasContainer, options).then(() =>
      {
        //hide structure tools
        this.molstarInstance.plugin.layout.updateProps({
          regionState: {left:'hidden', right:'hidden', bottom:'hidden',top:'full'}
        })
      });

    return new Promise(resolve => {
      this.molstarInstance.events.loadComplete.subscribe(resolve);
    });

  }

  updateSelections({ selections, showConfidence = false, altSelection=undefined }) {
    
    selections = selections.map(item => ({
      start_residue_number: item.start,
      end_residue_number: item.end,
      color: getRGBFromHex(item.color)
    }));
    
    if(altSelection)
    {
      let altSelect = altSelection.data;
      altSelect.push(...selections)
      selections = altSelect;
    }

    let params = {
      data: selections
    };
    
    if(!showConfidence)
    {
      params.nonSelectedColor = { r: 255, g: 255, b: 255 }; // color the rest of the molecule white
    }

    this.molstarInstance.visual.select(params);
  }

  focus(params) {
    this.molstarInstance.visual.focus(params);
  }

};
