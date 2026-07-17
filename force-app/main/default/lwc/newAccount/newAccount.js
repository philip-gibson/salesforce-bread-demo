import { LightningElement } from 'lwc';
import newAccountModal from "c/newAccountModal";

export default class NewAccount extends LightningElement {
  handleClick() {
    newAccountModal.open({
      size: "small",
      description: "Create a new account",
    }).then((result) => {
      if (result === "success") {
        this.dispatchEvent(new CustomEvent('success'));
      }
    });
  }
}
