import { LightningElement, api, wire } from 'lwc';
import getNewBreadOrders from '@salesforce/apex/AccountController.getNewBreadOrders';

export default class AccountBreadOrderPreparation extends LightningElement {
  @api recordId;

  newBreadOrders;
  error;

  @wire(getNewBreadOrders, { accountId: '$recordId' })
  wiredOrders({ data, error }) {
    if (data) {
      this.newBreadOrders = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.newBreadOrders = undefined;
    }
  }

  get hasOrders() {
    return this.newBreadOrders && this.newBreadOrders.length > 0;
  }
}
