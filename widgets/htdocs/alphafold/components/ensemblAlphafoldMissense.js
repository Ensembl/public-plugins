const COLOR_MAP = {
    min: { r: 0, g: 0, b: 187 },
    center: { r: 255, g: 255, b: 255 },
    max: { r: 255, g: 0, b: 0 },
}

const BASE_COLOR = { r: 100, g: 100, b: 100 };

export class EnsemblAlphafoldMissense
{
  constructor() {
    this.sequenceColors = [];
    this.hasMissenseLoaded = false;
    this.missenseSelection = {
      data: [
      { struct_asym_id: 'A', color: BASE_COLOR }
      ]
    }
  }
  
  getSelection() {
    return this.missenseSelection;
  }
  
  hasMissense()
  {
    return this.hasMissenseLoaded;
  }
  
  async loadMissense(annotationCSVUrl) {
    
    const missenseCSVResponse = await fetch(annotationCSVUrl);
    
    if (!missenseCSVResponse.ok) {
      this.hasMissenseLoaded = false; 
      console.log("Unable to load missense");
      return;
    }
    
    //process file
    this.hasMissenseLoaded = this.extractColors(await missenseCSVResponse.text());
  }

  extractColors(data){
    const DELIMITER = ',';
    const MUTATION_COLUMN = 0;
    const SCORE_COLUMN = 1;
    const N_HEADER_ROWS = 1;
  
    const lines = data.split('\n').filter(line => line.trim() !== '' && !line.trim().startsWith('#'));
    if (N_HEADER_ROWS > 0) lines.splice(0, N_HEADER_ROWS);
    const rows = lines.map(line => line.split(DELIMITER));
    
    //const scores = { [seq_id: number]: number[] } = {};
    const scores = {};
    for (const row of rows) {
      const mutation = row[MUTATION_COLUMN];
      const score = Number(row[SCORE_COLUMN]);
      const match = mutation.match(/([A-Za-z]+)([0-9]+)([A-Za-z]+)/);
      if (!match) 
      {
        console.log("Missense CSV parse error!");
        console(row);
        throw new Error(`FormatError: cannot parse "${mutation}" as a mutation (should look like Y123A)`);
      }
      const seq_id = match[2];

      if(!scores[seq_id])
      {
        scores[seq_id] = []
      }
      scores[seq_id].push(Number(score));
      
    }

    for (const seq_id in scores) {
      const aggrScore = this.mean(scores[seq_id]); // The original paper also uses mean (https://www.science.org/doi/10.1126/science.adg7492)
      const color = this.assignColor(aggrScore);
      this.sequenceColors.push([Number(seq_id), color]);
    }

    this.missenseSelection.data.push(
      ...this.sequenceColors.map((rc) =>  ({ 'struct_asym_id': 'A', 'residue_number': rc[0], 'color': rc[1]}))
    ) // TODO here I assume the model is always chain A, is it correct?

    return true;
  }
  
  mean(values) {
    return values.reduce((a, b) => a + b, 0) / values.length;
  }
  
  /** Map a score within [0, 1] to a color (0 -> COLOR_MAP.min, 0.5 -> COLOR_MAP.center, 1 -> COLOR_MAP.max) */
  assignColor(score) {
    if (score <= 0.5) {
      return this.mixColor(COLOR_MAP.min, COLOR_MAP.center, 2 * score);
    }
    else {
      return this.mixColor(COLOR_MAP.center, COLOR_MAP.max, 2 * score - 1);
    }
  }
  
  mixColor(color0, color1, q) {
    return {
      r: color0.r * (1 - q) + color1.r * q,
      g: color0.g * (1 - q) + color1.g * q,
      b: color0.b * (1 - q) + color1.b * q,
    };
  }

}

