import { LightningElement, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class DeliveryPlannerContainer extends LightningElement {
  deliveryPoints = [];

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
    const bakeryAccount = this.bakeryAccountData();
    this.deliveryPoints = [bakeryAccount, ...event.detail];
  }

  bakeryAccountData() {
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
    this.template.querySelector('c-route-calculator').calculateRoute();
  }

  resetDeliveryRoute() {
    this.template.querySelector('c-account-selector').resetAll();
    this.template.querySelector('c-route-calculator').resetAll();
  }
}
