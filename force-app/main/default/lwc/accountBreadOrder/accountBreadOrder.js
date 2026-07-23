import { LightningElement, api, wire } from 'lwc';
import getReadyOrders from '@salesforce/apex/BreadOrderController.getReadyOrders';

export default class AccountBreadOrder extends LightningElement {
  @api accountId;
  accountBreadOrders;
  error;

  @wire(getReadyOrders, { accountId: '$accountId' })
  wiredOrders({ data, error }) {
    if (data) {
      this.accountBreadOrders = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.accountBreadOrders = undefined;
    }
  }

  get total() {
    return this.accountBreadOrders.reduce((total, order) => total + order.Total__c)
  }

  get hasOrders() {
    return this.accountBreadOrders && this.accountBreadOrders.length > 0;
  }
}
