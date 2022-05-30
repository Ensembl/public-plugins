export class VepVariantController {

  constructor({ host, position, consequence}) {
    this.host = host;
    this.position = parseInt(position);
    this.consequence = consequence;
    this.isSelected = true;

    this.host.addController(this);

    this.onSelectionChange = this.onSelectionChange.bind(this);
    this.getSelection = this.getSelection.bind(this);
  }

  onSelectionChange(isSelected) {
    this.isSelected = isSelected;
  }

  // although this controller is responsible for a single variant,
  // it returns an array in order to be composable with the selections from other controllers
  getSelection() {
    if (!this.isSelected) {
      return [];
    }

    return [
      {
        start: this.position,
        end: this.position,
        color: 'red'
      }
    ];
  }
  
}
