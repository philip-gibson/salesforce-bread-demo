import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningModal from "lightning/modal";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import NAME_FIELD from "@salesforce/schema/Account.Name";
import SHIPPING_STREET_FIELD from "@salesforce/schema/Account.ShippingStreet";
import SHIPPING_CITY_FIELD from "@salesforce/schema/Account.ShippingCity";
import SHIPPING_STATE_FIELD from "@salesforce/schema/Account.ShippingState";
import SHIPPING_POSTALCODE_FIELD from "@salesforce/schema/Account.ShippingPostalCode";
import SHIPPING_COUNTRY_FIELD from "@salesforce/schema/Account.ShippingCountry";

export default class NewAccountModal extends LightningModal {
  objectApiName = ACCOUNT_OBJECT;
  fields = [
    NAME_FIELD, 
    SHIPPING_STREET_FIELD,
    SHIPPING_CITY_FIELD,
    SHIPPING_STATE_FIELD,
    SHIPPING_POSTALCODE_FIELD,
    SHIPPING_COUNTRY_FIELD
  ];

  handleSuccess() {
    const evt = new ShowToastEvent({
      title: "Account created",
      variant: "success",
    });
    this.dispatchEvent(evt);
    this.close("success");
  }

  handleClose() {
    this.close();
  }
}
