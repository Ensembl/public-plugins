import {
  fetchVariants
} from '../dataFetchers.js';


export class VariantsController {

  constructor(host) {
    this.host = host;
    this.host.addController(this);

    this.selectedSiftIndices = [];
    this.selectedPolyphenIndices = [];

    this.load = this.load.bind(this);
    this.onSelectionChange = this.onSelectionChange.bind(this);
    this.getSelectedPolyphenIndices = this.getSelectedPolyphenIndices.bind(this);
    this.getSelectedSiftVariants = this.getSelectedSiftVariants.bind(this);
  }

  async load(params) {
    const variants = await fetchVariants(params);
    this.variants = variants;
  }

  onSelectionChange({ type, selectedIndices }) {
    if (type === 'sift') {
      this.setSelectedSiftIndices(selectedIndices);
    } else if (type === 'polyphen') {
      this.setSelectedPolyphenIndices(selectedIndices);
    }
  }

  getSelectedSiftIndices() {
    return this.selectedSiftIndices;
  }

  setSelectedSiftIndices(indices) {
    this.selectedSiftIndices = indices;
    this.host.requestUpdate();
  }

  getSelectedPolyphenIndices() {
    return this.selectedPolyphenIndices;
  }

  setSelectedPolyphenIndices(indices) {
    this.selectedPolyphenIndices = indices;
    this.host.requestUpdate();
  }

  getSelectedSiftVariants() {
    return this.selectedSiftIndices.map(index => this.variants.sift[index]);
  }

  getSelectedPolyphenVariants() {
    return this.selectedPolyphenIndices.map(index => this.variants.polyphen[index]);
  }

}
