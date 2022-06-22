export class ConfidenceColorsController {

  constructor({ host, visible = true }) {
    this.host = host;
    this.visible = visible;

    this.host.addController(this);

    this.toggleVisibility = this.toggleVisibility.bind(this);
  }

  toggleVisibility() {
    this.visible = !this.visible;
    this.host.requestUpdate();
  }

}