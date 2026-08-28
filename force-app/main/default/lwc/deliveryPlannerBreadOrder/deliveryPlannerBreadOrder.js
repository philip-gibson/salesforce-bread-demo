import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import BreadOrderEvent from '@salesforce/messageChannel/BreadOrderEvent__c';
import getReadyBreadOrders from '@salesforce/apex/DeliveryPlannerController.getReadyBreadOrders';
import setBreadOrdersDelivered from '@salesforce/apex/DeliveryPlannerController.setBreadOrdersDelivered';

export default class DeliveryPlannerBreadOrder extends LightningElement {
  @api accountName;
  breadOrders;
  error;
  delivered = false;

  _accountId;

  @api
  get accountId() {
    return this._accountId;
  }
  set accountId(value) {
    this._accountId = value;
    this.breadOrders = undefined;
    this.error = undefined;
    this.delivered = false;
  }

  @wire(getReadyBreadOrders, { accountId: '$accountId' })
  wiredOrders({ data, error }) {
    if (data) {
      this.breadOrders = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.breadOrders = undefined;
    }
  }

  @wire(MessageContext)
  messageContext;

  get total() {
    return this.breadOrders.reduce((total, order) => total + order.total, 0.00).toFixed(2)
  }

  get hasOrders() {
    return this.breadOrders?.length > 0;
  }

  get isDelivered() {
    return this.delivered || this.breadOrders?.length === 0;
  }

  get isLoading() {
    return (
      this.accountId &&
      this.breadOrders === undefined &&
      this.error === undefined
    );
  }

  async handleDelivered() {
    if (this.hasOrders) {
      try {
        const breadOrderIds = this.breadOrders.map(order => order.id);
        await setBreadOrdersDelivered({ breadOrderIds });
        publish(this.messageContext, BreadOrderEvent, { eventType: 'delivered', accountId: this.accountId });
        this.delivered = true;
        this.breadOrders = [];
      } catch (error) {
        this.showErrorToast(error);
      }
    }
  }

  showErrorToast(_error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Bread Orders could not be set as delivered',
        message: 'An unexpected error occurred.',
        variant: 'error',
        mode: 'sticky',
      })
    );
  }
}
