import {
  fetchExons
} from '../dataFetchers.js';


export class ExonsController {

  constructor(host) {
    this.host = host;
    this.host.addController(this);

    this.selectedIndices = [];

    this.load = this.load.bind(this);
    this.onSelectionChange = this.onSelectionChange.bind(this);
    this.getSelectedExons = this.getSelectedExons.bind(this);
  }

  async load(params) {
    const exons = await fetchExons(params);
    this.exons = exons;
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

  getSelectedExons() {
    return this.selectedIndices.map(index => this.exons[index]);
  }

}
