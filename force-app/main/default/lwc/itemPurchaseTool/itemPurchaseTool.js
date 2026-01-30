import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getAccount from "@salesforce/apex/ItemPurchase.getAccount";
import getItem from "@salesforce/apex/ItemPurchase.getItem";
import isManager from "@salesforce/apex/ItemPurchase.isManager";
import checkout from "@salesforce/apex/ItemPurchase.checkout";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getItemCount from "@salesforce/apex/ItemPurchase.getItemCount";
import createItemWithImage from "@salesforce/apex/ItemPurchase.createItemWithImage";
import refreshApex from "@salesforce/apex";

export default class ItemPurchaseTool extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  account;
  items = [];
  isManager = false;
  error;
  searchItem = "";
  family = "";
  type = "";
  select = null;
  isOpen = false;
  cart = [];
  isCartOpen = false;
  isCreateItemOpen = false;
  itemCount = 0;
  newItemName = "";
  newItemDesc = "";
  newItemFamily = "";
  newItemType = "";
  newItemPrice;
  wiredItemsResult;

  cartColumns = [
    {
      label: "Name",
      fieldName: "Name",
      type: "text"
    },
    {
      label: "Price",
      fieldName: "Price__c",
      type: "currency"
    },
    {
      label: "Quantity",
      fieldName: "quantity",
      type: "number"
    },
    {
      type: "button",
      initialWidth: 100,
      typeAttributes: {
        label: "Remove",
        name: "remove",
        variant: "destructive"
      }
    }
  ];

  handleCartRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === "remove") {
      const item = this.cart.find((i) => i.Id === row.Id);

      if (item.quantity > 1) {
        item.quantity -= 1;
        this.cart = [...this.cart];
      } else {
        this.cart = this.cart.filter((i) => i.Id !== row.Id);
      }
    }
  }

  openCreateItem() {
    this.isCreateItemOpen = true;
  }

  closeCreateItem() {
    this.isCreateItemOpen = false;
  }

  @wire(getAccount, { accountId: "$recordId" })
  wiredAccount({ data, error }) {
    if (data) {
      this.account = data;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getItem, {
    family: "$family",
    type: "$type",
    searchItem: "$searchItem"
  })
  wiredItem(result) {
    this.wiredItemsResult = result;
    if (result.data) {
      this.items = result.data;
    }
  }

  @wire(getItemCount, {
    family: "$family",
    type: "$type",
    searchItem: "$searchItem"
  })
  wiredItemCount({ data, error }) {
    if (data !== undefined) {
      this.itemCount = data;
    } else if (error) {
      console.error("Item count error", error);
      this.itemCount = 0;
    }
  }

  @wire(isManager)
  wiredManager({ data }) {
    this.isManager = data;
  }

  handleItemCreated() {
    this.isCreateItemOpen = false;

    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: "Item created successfully",
        variant: "success"
      })
    );
  }

  handleSearch(event) {
    this.searchItem = event.target.value;
  }

  handleFamily(event) {
    this.family = event.target.value;
  }

  handleType(event) {
    this.type = event.target.value;
  }

  handleName(event) {
    this.newItemName = event.target.value;
  }
  handleDesc(event) {
    this.newItemDesc = event.target.value;
  }
  handleFamilyNew(event) {
    this.newItemFamily = event.target.value;
  }
  handleTypeNew(event) {
    this.newItemType = event.target.value;
  }
  handlePrice(event) {
    this.newItemPrice = event.target.value;
  }

  handleCheckout() {
    const cartItems = this.cart.map((item) => ({
      itemId: item.Id,
      quantity: item.quantity
    }));

    checkout({
      accountId: this.recordId,
      items: cartItems
    })
      .then((purchaseId) => {
        this.navigateToPurchase(purchaseId);
        this.cart = [];
        this.isCartOpen = false;
      })
      .catch(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Checkout failed",
            message: "Unable to complete checkout",
            variant: "error"
          })
        );
      });
  }

  get isCheckoutDisabled() {
    return this.cart.length === 0;
  }

  openDetails(event) {
    const itemId = event.currentTarget.dataset.id;
    this.select = this.items.find((item) => item.Id === itemId);
    this.isOpen = true;
  }

  closeDetails() {
    this.select = null;
    this.isOpen = false;
  }

  addToCart(event) {
    const itemId = event.currentTarget.dataset.id;
    const item = this.items.find((i) => i.Id === itemId);
    const existing = this.cart.find((i) => i.Id === itemId);

    if (existing) {
      existing.quantity = (existing.quantity || 1) + 1;
      this.cart = [...this.cart];
    } else {
      this.cart = [...this.cart, { ...item, quantity: 1 }];
    }
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Added to cart",
        message: `${item.Name} added`,
        variant: "success"
      })
    );
  }

  get cartLabel() {
    return `Cart (${this.cartCount})`;
  }

  removeFromCart(event) {
    const itemId = event.currentTarget.dataset.id;
    const item = this.cart.find((i) => i.Id === itemId);
    if (item.quantity > 1) {
      item.quantity -= 1;
      this.cart = [...this.cart];
    } else {
      this.cart = this.cart.filter((i) => i.Id !== itemId);
    }
  }

  get cartCount() {
    return this.cart.reduce((sum, item) => {
      return sum + (item.quantity || 0);
    }, 0);
  }

  openCart() {
    this.isCartOpen = true;
  }

  closeCart() {
    this.isCartOpen = false;
  }

  navigateToPurchase(purchaseId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: purchaseId,
        objectApiName: "Purchase__c",
        actionName: "view"
      }
    });
  }

  get familyOp() {
    return [
      { label: "All", value: " " },
      { label: "Family 1", value: "Family 1" },
      { label: "Family 2", value: "Family 2" },
      { label: "Family 3", value: "Family 3" },
      { label: "Family 4", value: "Family 4" }
    ];
  }

  get typeOp() {
    return [
      { label: "All", value: " " },
      { label: "Type 1", value: "Type 1" },
      { label: "Type 2", value: "Type 2" },
      { label: "Type 3", value: "Type 3" },
      { label: "Type 4", value: "Type 4" }
    ];
  }

  saveItem() {
    const item = {
      Name: this.newItemName,
      Description__c: this.newItemDesc,
      Family__c: this.newItemFamily,
      Type__c: this.newItemType,
      Price__c: this.newItemPrice
    };

    createItemWithImage({ item })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Item created successfully",
            variant: "success"
          })
        );

        this.isCreateItemOpen = false;
        return refreshApex(this.wiredItemsResult);
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body?.message || "Failed to create item",
            variant: "error"
          })
        );
      });
  }
}
