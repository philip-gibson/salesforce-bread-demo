import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import BreadOrderEvent from '@salesforce/messageChannel/BreadOrderEvent__c';
import getNewBreadOrders from '@salesforce/apex/AccountController.getNewBreadOrders';
import setBreadOrdersToReady from '@salesforce/apex/AccountController.setBreadOrdersToReady';

export default class AccountBreadOrderPreparation extends LightningElement {
  @api recordId;

  subscription;
  wiredOrdersResult;
  newBreadOrders;
  error;

  @wire(getNewBreadOrders, { accountId: '$recordId' })
  wiredOrders(result) {
    this.wiredOrdersResult = result;
    const { data, error } = result;
    if (data) {
      this.newBreadOrders = data.map(order => {
        return {
          id: order.Id,
          name: order.Bread__r.Name,
          quantity: order.Quantity__c,
          selected: false,
        }
      });
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.newBreadOrders = undefined;
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
    if (message?.eventType === 'created') {
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
    return this.newBreadOrders && this.newBreadOrders.length > 0;
  }

  get someSelected() {
    return this.newBreadOrders.some(order => order.selected);
  }

  get disabled() {
    return !this.hasOrders || !this.someSelected;
  }

  handleClick(event) {
    const orderId = event.target.dataset.orderId;
    this.newBreadOrders = this.newBreadOrders.map(order =>
      order.id === orderId ? { ...order, selected: !order.selected } : order
    );
  }

  async readyForDelivery() {
    if (this.someSelected) {
      try {
        const breadOrderIds = this.newBreadOrders.filter(order => order.selected).map(order => order.id);
        await setBreadOrdersToReady({ breadOrderIds });
        publish(this.messageContext, BreadOrderEvent, { eventType: 'ready' });
        await refreshApex(this.wiredOrdersResult);
      } catch (error) {
        this.showErrorToast(error);
      }
    }
  }

  showErrorToast(_error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Bread Order could not be set as ready for delivery',
        message: 'An unexpected error occurred.',
        variant: 'error',
        mode: 'sticky',
      })
    );
  }
}
