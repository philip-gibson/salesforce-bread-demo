import getImage from '@salesforce/apex/BreadController.getImage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, wire } from 'lwc';

export const acceptedFileTypes = new Set(['png', 'jpg', 'jpeg']);

export default class BreadImage extends LightningElement {
  @api recordId;
  doneLoading = false;
  breadName;
  fileType;
  downloadUrl;

  @wire(getImage, { recordId: '$recordId' })
  imageDTO({ data, error }) {
    if (data) {
      this.doneLoading = true;
      this.breadName = data.breadName;
      this.fileType = data.fileType;
      this.downloadUrl = data.downloadUrl;
    } else if (error) {
      console.error(error);
      this.showErrorToast();
    }
  }

  get hasImage() {
    return !!(this.downloadUrl && this.fileType && acceptedFileTypes.has(this.fileType.toLowerCase()));
  }

  showErrorToast() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Error loading image',
        message: 'An unexpected error occurred.',
        variant: 'error',
        mode: 'sticky',
      })
    );
  }
}
