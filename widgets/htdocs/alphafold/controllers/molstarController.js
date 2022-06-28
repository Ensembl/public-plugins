import { getRGBFromHex } from '../colorHelpers.js';

export class MolstarController {

  constructor(host) {
    this.host = host;
    this.host.addController(this);

    this.loadScript = this.loadScript.bind(this);
    this.renderAlphafoldStructure = this.renderAlphafoldStructure.bind(this);
    this.updateSelections = this.updateSelections.bind(this);
  }

  async loadScript(urlRoot) {
    await new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = `${urlRoot}/assets/js/af-pdbe-molstar-plugin-1.1.1.js`;
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
    this.molstarInstance = new PDBeMolstarPlugin();
  }

  renderAlphafoldStructure({ moleculeId, urlRoot, canvasContainer }) {
    const options = {
      customData: {
        url: `${urlRoot}/files/${moleculeId}-model_v1.cif`,
        format: 'cif'
      },
      bgColor: { r: 255, g: 255, b: 255 },
      isAfView: true,
      hideCanvasControls: ['selection', 'animation', 'controlToggle', 'controlInfo']
    };

    this.molstarInstance.render(canvasContainer, options);

    return new Promise(resolve => {
      this.molstarInstance.events.loadComplete.subscribe(resolve);
    });

    /**
     * .then(() => {
          this.molstarInstance.visual.focus([{
            start_residue_number: 7,
            end_residue_number: 7
          }]);
        })
     */
  }

  updateSelections({ selections, showConfidence = false }) {
    // decide on how the showConfidence should work

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

};
