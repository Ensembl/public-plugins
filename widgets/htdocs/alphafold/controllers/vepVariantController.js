export class VepVariantController {

  constructor({ host, position, consequence}) {
    this.host = host;
    this.position = parseInt(position);
    this.consequence = consequence;

    this.host.addController(this);

    this.getSelection = this.getSelection.bind(this);
  }

  // although this controller is responsible for a single variant,
  // it returns an array in order to be composable with the selections from other controllers
  getSelection() {
    const variantSelectionData = {
      start: this.position,
      end: this.position,
      color: 'magenta'
    };

    return [variantSelectionData];
  }
  
}
