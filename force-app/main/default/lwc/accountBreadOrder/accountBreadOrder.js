import { LightningElement, api } from 'lwc';

export default class AccountBreadOrder extends LightningElement {
  @api accountId;
  accountBreadOrder;

  get breadOrder() {
    return this.accountBreadOrder ? this.accountBreadOrder : this.accountId;
  }
}
