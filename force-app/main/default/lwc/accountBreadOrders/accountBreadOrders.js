import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import BreadOrderEvent from '@salesforce/messageChannel/BreadOrderEvent__c';
import getBreadOrdersByAccountId from '@salesforce/apex/AccountController.getBreadOrdersByAccountId';

const REFRESH_EVENT_TYPES = ['ready', 'delivered', 'cancelled'];

export default class AccountBreadOrders extends NavigationMixin(LightningElement) {
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
        { scope: APPLICATION_SCOPE },
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  async handleMessage(message) {
    if (message?.accountId === this.recordId && REFRESH_EVENT_TYPES.includes(message?.eventType)) {
      await refreshApex(this.wiredOrdersResult);
    }
  }

  connectedCallback() {
    this.subscribeToMessageChannel();
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  get hasReadyOrders() {
    return this.ready.length > 0;
  }

  get ready() {
    return this.accountBreadOrders ? this.accountBreadOrders.filter(order => order.Status__c.toLowerCase() === 'ready') : [];
  }

  get hasDeliveredOrders() {
    return this.delivered.length > 0;
  }

  get delivered() {
    return this.accountBreadOrders ? this.accountBreadOrders.filter(order => order.Status__c.toLowerCase() === 'delivered') : [];
  }

  get hasCancelledOrders() {
    return this.cancelled.length > 0;
  }

  get cancelled() {
    return this.accountBreadOrders ? this.accountBreadOrders.filter(order => order.Status__c.toLowerCase() === 'cancelled') : [];
  }

  goToDeliveries() {
    this[NavigationMixin.Navigate]({
      type: 'standard__navItemPage',
      attributes: {
        apiName: 'Delivery_Planner',
      },
      state: {
        c__recordId: this.recordId,
      }
    });
  }
}
