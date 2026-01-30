public with sharing class ItemPurchase {
  @AuraEnabled(cacheable=true)
  public static Account getAccount(Id accountId) {
    if (accountId == null) {
      return null;
    }
    Account acc = [
      SELECT Id, Name, AccountNumber, Industry
      FROM Account
      WHERE Id = :accountId
      LIMIT 1
    ];
    return acc;
  }

  @AuraEnabled(cacheable=true)
  public static List<Item__c> getItem(
    String family,
    String type,
    String searchItem
  ) {
    String search = (searchItem == null) ? null : '%' + searchItem + '%';
    List<Item__c> items = [
      SELECT Id, Name, Description__c, Family__c, Type__c, Price__c, Image__c
      FROM Item__c
      WHERE
        Family__c LIKE :('%' + family + '%')
        AND Type__c LIKE :('%' + type + '%')
        AND (Name LIKE :search
        OR Description__c LIKE :search)
      ORDER BY Name
    ];
    return items;
  }

  @AuraEnabled
  public static Id createItemWithImage(Item__c item) {
    if (item == null || String.isBlank(item.Name)) {
      throw new AuraHandledException('Item name is required');
    }

    String imageUrl = Unsplash.getImageUrl(item.Name);
    item.Image__c = imageUrl;

    insert item;
    return item.Id;
  }

  @AuraEnabled(cacheable=true)
  public static Integer getItemCount(
    String family,
    String type,
    String searchItem
  ) {
    String search = (searchItem == null) ? null : '%' + searchItem + '%';
    Integer count = [
      SELECT COUNT()
      FROM Item__c
      WHERE
        Family__c LIKE :('%' + family + '%')
        AND Type__c LIKE :('%' + type + '%')
        AND (Name LIKE :search
        OR Description__c LIKE :search)
    ];
    return count;
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isManager() {
    User a = [
      SELECT IsManager__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];
    return a.IsManager__c;
  }

  public class CartItemDTO {
    @AuraEnabled
    public Id itemId;
    @AuraEnabled
    public Integer quantity;
  }

  @AuraEnabled
  public static Id checkout(Id accountId, List<CartItemDTO> items) {
    if (accountId == null || items == null || items.isEmpty()) {
      throw new AuraHandledException('Invalid checkout data');
    }

    Purchase__c purchase = new Purchase__c(
      ClientId__c = accountId,
      Name = 'Purchase - ' + Datetime.now().format('yyyy-MM-dd HH:mm')
    );
    insert purchase;

    Set<Id> itemIds = new Set<Id>();
    for (CartItemDTO ci : items) {
      itemIds.add(ci.itemId);
    }

    Map<Id, Item__c> itemMap = new Map<Id, Item__c>(
      [SELECT Id, Price__c FROM Item__c WHERE Id IN :itemIds]
    );

    List<PurchaseLine__c> lines = new List<PurchaseLine__c>();

    for (CartItemDTO ci : items) {
      Item__c item = itemMap.get(ci.itemId);

      lines.add(
        new PurchaseLine__c(
          PurchaseId__c = purchase.Id,
          Item__c = ci.itemId,
          Amount__c = ci.quantity,
          UnitCost__c = item.Price__c
        )
      );
    }

    insert lines;
    return purchase.Id;
  }
}
