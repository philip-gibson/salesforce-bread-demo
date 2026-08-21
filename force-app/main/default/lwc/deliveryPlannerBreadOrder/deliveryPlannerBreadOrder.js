import { LightningElement, api, wire } from 'lwc';
import getReadyOrders from '@salesforce/apex/DeliveryPlannerController.getReadyOrders';

export default class DeliveryPlannerBreadOrder extends LightningElement {
  @api accountName;
  accountBreadOrders;
  error;

  _accountId;

  @api
  get accountId() {
    return this._accountId;
  }
  set accountId(value) {
    this._accountId = value;
    this.accountBreadOrders = undefined;
    this.error = undefined;
  }

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
    return this.accountBreadOrders.reduce((total, order) => total + order.Total__c, 0.00).toFixed(2)
  }

  get hasOrders() {
    return this.accountBreadOrders && this.accountBreadOrders.length > 0;
  }

  get isLoading() {
    return (
      this.accountId &&
      this.accountBreadOrders === undefined &&
      this.error === undefined
    );
  }
}
