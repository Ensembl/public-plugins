export class ConfidenceMissenseColorsController {

  constructor({ host, showConfidence = true }) {
    this.host = host;
    this.showConfidence = showConfidence;
    this.host.addController(this);
    this.toggle = this.toggle.bind(this);
  }
  
  getShowConfidence() 
  {
    return this.showConfidence;
  }

  toggle() {
    this.showConfidence = !this.showConfidence;
    this.host.requestUpdate();
  }

}