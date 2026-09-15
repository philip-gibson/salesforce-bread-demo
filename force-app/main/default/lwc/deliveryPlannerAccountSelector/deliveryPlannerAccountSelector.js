import { LightningElement, api, wire } from 'lwc';
import { gql, graphql, refreshGraphQL } from 'lightning/uiGraphQLApi';

export default class DeliveryPlannerAccountSelector extends LightningElement {
  @api selectedAccountId;
  _accountList;

  refreshList() {
    return refreshGraphQL(this._accountList);
  }

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
          street: account.ShippingStreet,
          city: account.ShippingCity,
          state: account.ShippingState,
          postalCode: account.ShippingPostalCode,
          lat: account.ShippingLatitude,
          lng: account.ShippingLongitude,
        };
      });
    this.dispatchEvent(new CustomEvent("selected", { detail: selected }));
  }

  @api resetAll() {
    this.selectedAccountId = null;
    Array.from(this.template.querySelectorAll("lightning-input"))
      .filter(input => input.type === "checkbox")
      .forEach(input => input.checked = false);
  }

  @wire(graphql, {
      query: gql`
        query getAccounts {
          uiapi {
            query {
              Account (
                first: 25
                where: {
                  and: [
                    { ShippingState: { eq: "California" } }
                    { ShippingLongitude: { ne: null } }
                    { Name: { ne: "Salesforce Bakery" } }
                    { Id: {
                        inq: {
                          Bread_Order__c: {
                            Status__c: { eq: "Ready" }
                          }
                          ApiName: "Account__c"
                        }
                      }
                    }
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
  }) wiredAccounts(result) {
    this._accountList = result;
  }

  get accounts() {
    return this._accountList?.data?.uiapi?.query?.Account?.edges?.map(edge => ({
      Id: edge.node.Id,
      Name: edge.node.Name?.value,
      ShippingStreet: edge.node.ShippingAddress?.ShippingStreet?.value,
      ShippingCity: edge.node.ShippingAddress?.ShippingCity?.value,
      ShippingState: edge.node.ShippingAddress?.ShippingState?.value,
      ShippingPostalCode: edge.node.ShippingAddress?.ShippingPostalCode?.value,
      ShippingLatitude: edge.node.ShippingAddress?.ShippingLatitude?.value,
      ShippingLongitude: edge.node.ShippingAddress?.ShippingLongitude?.value,
      Checked: edge.node.Id === this.selectedAccountId,
    })) ?? [];
  };

  get maxAccounts() {
    return this._accountList?.length === 25;
  }

  renderedCallback() {
    if (this._accountList && this.selectedAccountId) this.handleCheckboxChange();
  }
}
