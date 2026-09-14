import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class DeliveryPlannerContainer extends LightningElement {
  deliveryPoints = [];
  breadOrderAccountId;
  breadOrderAccountName;
  selectedAccountId;

  @wire(CurrentPageReference)
  getPageReference(pageRef) {
    if (pageRef?.state) {
      this.selectedAccountId = pageRef.state.c__recordId;
    }
  }

  @wire(graphql, {
    query: gql`
      query getAccounts {
        uiapi {
          query {
            Account (
              where: { Name: { eq: "Salesforce Bakery" } }
            ) {
              edges {
                node {
                  Id
                  Name { value }
                  ShippingAddress {
                    ShippingCity { value }
                    ShippingPostalCode { value }
                    ShippingState { value }
                    ShippingStreet { value }
                    ShippingLatitude { value }
                    ShippingLongitude { value }
                  }
                }
              }
            }
          }
        }
      }
    `
  }) salesforceBakery;

  updateDeliveryPoints(event) {
    this.deliveryPoints = [this.bakeryAccount, ...event.detail];
  }

  get bakeryAccount() {
    const account = this.salesforceBakery?.data?.uiapi?.query?.Account?.edges?.[0]?.node;
    return account ? {
      id: 0,
      accountId: account.Id,
      name: account.Name.value,
      street: account.ShippingAddress.ShippingStreet.value,
      city: account.ShippingAddress.ShippingCity.value,
      state: account.ShippingAddress.ShippingState.value,
      postalCode: account.ShippingAddress.ShippingPostalCode.value,
      lat: account.ShippingAddress.ShippingLatitude.value,
      lng: account.ShippingAddress.ShippingLongitude.value,
    } : {};
  }

  calculateDeliveryRoute() {
    if (this.disableButton) return;
    this.template.querySelector('c-delivery-planner-route-calculator').calculateRoute();
    this.template.querySelector('c-delivery-planner-bread-orders').getBreadOrders(this.breadOrderAccountIds);
  }

  resetDeliveryRoute() {
    this.template.querySelector('c-delivery-planner-account-selector').resetAll();
    this.template.querySelector('c-delivery-planner-route-calculator').resetAll();
    this.template.querySelector('c-delivery-planner-bread-orders').resetAll();
    this.deliveryPoints = [];
    this.breadOrderAccountId = null;
    this.breadOrderAccountName = null;
  }

  viewBreadOrder(event) {
    this.breadOrderAccountId = event.detail;
    this.breadOrderAccountName = this.deliveryPoints.find(p => p.accountId === event.detail)?.name;
  }

  get disableButton() {
    return this.deliveryPoints.length < 2 || this.deliveryPoints.length > 11;
  }

  get breadOrderAccountIds() {
    const accounts = this.deliveryPoints.filter(account => account.accountId != this.bakeryAccount.accountId);
    return accounts.map(account => account.accountId);
  }
}
