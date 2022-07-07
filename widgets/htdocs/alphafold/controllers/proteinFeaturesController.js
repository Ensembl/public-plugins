import {
  fetchProteinFeatures
} from '../dataFetchers.js';


export class ProteinFeaturesController {

  constructor(host) {
    this.host = host;
    this.host.addController(this);

    this.proteinFeatures = {};

    this.load = this.load.bind(this);
    this.onSelectionChange = this.onSelectionChange.bind(this);
    this.getSelectedFeatures = this.getSelectedFeatures.bind(this);
  }

  async load(params) {
    const proteinFeatures = await fetchProteinFeatures(params);
    this.proteinFeatures = proteinFeatures;
    this.selectedIndices = Object.keys(proteinFeatures)
      .reduce((obj, key) => {
        obj[key] = [];
        return obj;
      }, {});
  }

  onSelectionChange(selectedIndices) {
    this.setSelectedIndices(selectedIndices);
  }

  getSelectedIndices() {
    return this.selectedIndices;
  }

  setSelectedIndices(indices) {
    this.selectedIndices = indices;
    this.host.requestUpdate();
  }

  getSelectedFeatures() {
    if (!this.selectedIndices) {
      return [];
    }
    return Object.entries(this.selectedIndices)
      .flatMap(([key, indices]) => indices.map(index => this.proteinFeatures[key][index]));
  }

}
