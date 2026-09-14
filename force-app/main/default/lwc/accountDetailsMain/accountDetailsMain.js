import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from "@salesforce/schema/Account.Name";
import CANCELLED_FIELD from "@salesforce/schema/Account.Cancelled_Bread_Orders__c";
import DELIVERED_FIELD from "@salesforce/schema/Account.Delivered_Bread_Orders__c";
import SHIPPING_ADDRESS_FIELD from "@salesforce/schema/Account.ShippingAddress";
import SHIPPING_STREET_FIELD from "@salesforce/schema/Account.ShippingStreet";
import SHIPPING_POSTAL_CODE_FIELD from "@salesforce/schema/Account.ShippingPostalCode";

const FIELDS = [SHIPPING_STREET_FIELD, SHIPPING_POSTAL_CODE_FIELD];

export default class AccountDetailsMain extends LightningElement {
  @api recordId;
  @api objectApiName;
  accountFields = [NAME_FIELD, SHIPPING_ADDRESS_FIELD];
  breadOrderFields = [DELIVERED_FIELD, CANCELLED_FIELD];
  zoomLevel = 12;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  account;

  get mapMarkers() {
    return [
      {
        location: {
          Street: getFieldValue(this.account.data, SHIPPING_STREET_FIELD),
          PostalCode: getFieldValue(this.account.data, SHIPPING_POSTAL_CODE_FIELD),
          State: "CA",
          Country: "USA",
        },
      },
    ];
  }
}
