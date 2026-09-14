import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import BreadOrderEvent from '@salesforce/messageChannel/BreadOrderEvent__c';
import getReadyBreadOrders from '@salesforce/apex/DeliveryPlannerController.getReadyBreadOrders';
import setBreadOrdersDelivered from '@salesforce/apex/DeliveryPlannerController.setBreadOrdersDelivered';

export default class DeliveryPlannerBreadOrders extends LightningElement {
  breadOrders = [];
  delivered = [];

  @api async getBreadOrders(accountIds) {
    try {
      this.accountIds = accountIds;
      this.breadOrders = await getReadyBreadOrders({ accountIds });
    } catch (_error) {
      this.showErrorToast('Bread Orders not found');
    }
  }

  @api resetAll() {
    this.breadOrders = [];
    this.delivered = [];
  }

  @wire(MessageContext)
  messageContext;

  get hasBreadOrders() {
    return this.breadOrders.length > 0;
  }

  get displayBreadOrders() {
    const deliveredIds = new Set(this.delivered);
    return this.breadOrders.map(order => ({
      ...order,
      disabled: deliveredIds.has(order.accountId),
      textClass: deliveredIds.has(order.accountId) ? 'order-delivered' : 'order-ready',
    }));
  }

  async handleDelivered(event) {
    const accountId = event.target.dataset.id;
    if (this.hasBreadOrders && !this.delivered.includes(accountId)) {
      try {
        this.delivered = [...this.delivered, accountId];
        const breadOrderAccount = this.breadOrders.find(order => order.accountId === accountId);
        const breadOrderIds = breadOrderAccount.breadOrders.map(bo => bo.id);
        await setBreadOrdersDelivered({ breadOrderIds });
        publish(this.messageContext, BreadOrderEvent, { eventType: 'delivered', accountId });
      } catch (_error) {
        this.showErrorToast('Bread Orders not delivered');
        this.delivered = this.delivered.filter(id => id !== accountId);
      }
    }
  }

  showErrorToast(error) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: error,
        message: 'An unexpected error occurred.',
        variant: 'error',
        mode: 'sticky',
      })
    );
  }
}
