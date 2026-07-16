import { LightningElement, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class AccountSelector extends LightningElement {
  handleCheckboxChange() {
    const checkedIds = new Set(
      Array.from(this.template.querySelectorAll("lightning-input"))
        .filter((element) => element.checked)
        .map((element) => element.dataset.id)
    );

    const selected = this.accounts
      .filter((account) => checkedIds.has(account.Id))
      .map((account, index) => {
        return {
          id: index + 1,
          accountId: account.Id,
          name: account.Name,
          lat: account.ShippingLatitude,
          lng: account.ShippingLongitude,
        };
      });
    this.dispatchEvent(new CustomEvent("selected", { detail: selected }));
  }

  @wire(graphql, {
      query: gql`
        query getAccounts {
          uiapi {
            query {
              Account (
                first: 50
                where: {
                  and: [
                    { ShippingLongitude: { ne: null } }
                    { Name: { ne: "Salesforce Bakery" } }
                  ]
                }
                orderBy: { Name: { order: ASC } }
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
  }) accountList;

  get accounts() {
    return this.accountList?.data?.uiapi?.query?.Account?.edges?.map(edge => ({
      Id: edge.node.Id,
      Name: edge.node.Name?.value,
      ShippingStreet: edge.node.ShippingAddress?.ShippingStreet?.value,
      ShippingCity: edge.node.ShippingAddress?.ShippingCity?.value,
      ShippingState: edge.node.ShippingAddress?.ShippingState?.value,
      ShippingPostalCode: edge.node.ShippingAddress?.ShippingPostalCode?.value,
      ShippingLatitude: edge.node.ShippingAddress?.ShippingLatitude?.value,
      ShippingLongitude: edge.node.ShippingAddress?.ShippingLongitude?.value,
    })) ?? [];
  };
}
