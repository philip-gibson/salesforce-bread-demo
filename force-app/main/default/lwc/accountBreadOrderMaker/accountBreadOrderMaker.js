import { LightningElement, api, wire } from 'lwc';
import LightningConfirm from "lightning/confirm";
import getBreads from '@salesforce/apex/AccountController.getBreads';

export default class AccountBreadOrderMaker extends LightningElement {
  selectedBread;
  quantity = 0;
  breads;
  error;
  _recordId;
  
  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
  }

  @wire(getBreads, { recordId: '$recordId' })
  wiredOrders({ data, error }) {
    if (data) {
      this.breads = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.breads = undefined;
    }
  }

  get options() {
    if (!this.breads || this.breads.length === 0) return []
    return this.breads.map(bread => {
      return { label: bread.Name, value: bread.Id }
    });
  }

  handleChangeBread(event) {
    this.selectedBread = event.detail.value;
  }

  handleChangeQuantity(event) {
    this.quantity = event.detail.value;
  }

  handleBlurBread() {
    this.validateBread();
  }

  handleBlurQuantity() {
    this.validateQuantity();
  }

  async handleOrder() {
    this.validateBread();
    this.validateQuantity();
    const breadSelector = this.template.querySelector(".bread-selector");
    const quantityInput = this.template.querySelector(".quantity-input");
    if (!breadSelector.validity.valid || !quantityInput.validity.valid) {
      return;
    }

    const bread = this.breads.find(bread => bread.Id === this.selectedBread);
    const result = await LightningConfirm.open({
      message: 'Create an order for ' + this.quantity + ' x ' + bread.Name,
      label: 'New bread order',
      theme: 'inverse',
    });
    if (result) {
      // create bread order
      this.handleReset()
    }
  }

  handleReset() {
    this.selectedBread = undefined;
    const breadSelector = this.template.querySelector(".bread-selector");
    breadSelector.setCustomValidity("");
    breadSelector.reportValidity();

    this.quantity = 0;
    const quantityInput = this.template.querySelector(".quantity-input");
    quantityInput.setCustomValidity("");
    quantityInput.reportValidity();
  }

  validateBread() {
    const breadSelector = this.template.querySelector(".bread-selector");
    if (!this.selectedBread) {
      breadSelector.setCustomValidity("Bread must be selected.");
    } else {
      breadSelector.setCustomValidity("");
    }
    breadSelector.reportValidity();
  }

  validateQuantity() {
    const quantityInput = this.template.querySelector(".quantity-input");
    if (this.quantity === 0) {
      quantityInput.setCustomValidity("Quantity must be 1 or more.");
    } else if (this.quantity >= 100) {
      quantityInput.setCustomValidity("Quantity must be less than 100.");
    } else {
      quantityInput.setCustomValidity("");
    }
    quantityInput.reportValidity();
  }
}
