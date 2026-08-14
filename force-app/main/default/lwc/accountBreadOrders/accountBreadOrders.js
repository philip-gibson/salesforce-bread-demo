import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import BreadOrderEvent from '@salesforce/messageChannel/BreadOrderEvent__c';
import getBreadOrdersByAccountId from '@salesforce/apex/AccountController.getBreadOrdersByAccountId';

export default class AccountBreadOrders extends LightningElement {
  @api recordId;

  subscription;
  wiredOrdersResult;
  accountBreadOrders;
  error;

  @wire(getBreadOrdersByAccountId, { recordId: '$recordId' })
  wiredOrders(result) {
    this.wiredOrdersResult = result;
    const { data, error } = result;
    if (data) {
      this.accountBreadOrders = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.accountBreadOrders = undefined;
    }
  }

  @wire(MessageContext)
  messageContext;

  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        BreadOrderEvent,
        (message) => this.handleMessage(message),
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  async handleMessage(message) {
    if (message?.eventType === 'ready') {
      await refreshApex(this.wiredOrdersResult);
    }
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
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
