import { LightningElement, api, wire } from 'lwc';
import getBreadOrdersByAccountId from '@salesforce/apex/BreadOrderController.getBreadOrdersByAccountId';

export default class AccountBreadOrders extends LightningElement {
  @api recordId;

  accountBreadOrders;
  error;

  @wire(getBreadOrdersByAccountId, { recordId: '$recordId' })
  wiredOrders({ data, error }) {
    if (data) {
      this.accountBreadOrders = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.accountBreadOrders = undefined;
    }
  }

  get hasOrders() {
    return this.accountBreadOrders && this.accountBreadOrders.length > 0;
  }

  get ready() {
    return this.accountBreadOrders ? this.accountBreadOrders.filter(order => order.Status__c.toLowerCase() === 'ready') : [];
  }

  get total() {
    return this.ready.reduce((total, order) => total + order.Total__c, 0.00).toFixed(2)
  }

  get delivered() {
    return this.accountBreadOrders ? this.accountBreadOrders.filter(order => order.Status__c.toLowerCase() === 'delivered') : [];
  }

  get cancelled() {
    return this.accountBreadOrders ? this.accountBreadOrders.filter(order => order.Status__c.toLowerCase() === 'cancelled') : [];
  }
}
