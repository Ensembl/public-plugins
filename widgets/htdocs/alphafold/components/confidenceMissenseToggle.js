import { html, css, LitElement } from 'https://unpkg.com/lit@2.2.5/index.js?module';

export class ConfidenceMissenseToggle extends LitElement {

  static get styles() {

    return css`
    .panel-title {
        display: flex;
        align-items: center;
        justify-content: space-between;
        background-color: var(--main-dark);
        color: white;
        font-weight: bold;
        padding: 4px 28px 4px 4px;
      }
    `
  }
  
  static get properties() {
    return {
      isConfidenceSelected: { attribute: false }
    }
  }
  
  createOption(id,label,isChecked)
  {
    if(isChecked)
    {
    return html`
      <input type="radio" name="toggleConfidenceMissense" @change=${this.onToggleChanged}
      id=${id} checked /><label for=${id}>${label}</label>
    `;
    }
    else
    {
      return html`
      <input type="radio" name="toggleConfidenceMissense" @change=${this.onToggleChanged}
      id=${id} /><label for=${id}>${label}</label>
    `;
    }
  }
  
  render() {
    
    let confidenceChecked = this.createOption('tconfidence','Model Confidence',this.isConfidenceSelected);
    let missenseChecked = this.createOption('tmissense','AlphaMissense Pathogenicity',!this.isConfidenceSelected);
    
    return html`
    <div class="panel-title">
    <span>Toggle</span>
    </div>
      <div class="body">
        <div class="row">
          ${confidenceChecked}
          ${missenseChecked}
        </div>
      </div>
    `};
};

customElements.define('confidence-missense-toggle', ConfidenceMissenseToggle);