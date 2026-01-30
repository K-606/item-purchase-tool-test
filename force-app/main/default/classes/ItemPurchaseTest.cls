@IsTest
public class ItemPurchaseTest {
  @TestSetup
  static void setupData() {
    Account acc = new Account(
      Name = 'Test Account',
      AccountNumber = 'ACC-001',
      Industry = 'Chemicals'
    );
    insert acc;

    List<Item__c> items = new List<Item__c>{
      new Item__c(
        Name = 'Item One',
        Family__c = 'Family 1',
        Type__c = 'Type 1',
        Price__c = 10
      ),
      new Item__c(
        Name = 'Item Two',
        Family__c = 'Family 2',
        Type__c = 'Type 2',
        Price__c = 20
      )
    };
    insert items;

    User u = [
      SELECT Id, IsManager__c
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    u.IsManager__c = true;
    update u;
  }

  @IsTest
  static void testGetAccount() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    Account result = ItemPurchase.getAccount(acc.Id);
    Test.stopTest();

    System.assertNotEquals(null, result);
    System.assertEquals(acc.Id, result.Id);
  }

  @IsTest
  static void testGetItem() {
    Test.startTest();
    List<Item__c> items = ItemPurchase.getItem('Family 1', 'Type 1', 'Item');
    Test.stopTest();

    System.assertEquals(1, items.size());
    System.assertEquals('Item One', items[0].Name);
  }

  @IsTest
  static void testIsManager() {
    Test.startTest();
    Boolean result = ItemPurchase.isManager();
    Test.stopTest();

    System.assertEquals(true, result);
  }

  @IsTest
  static void testCheckoutAndTrigger() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    List<Item__c> items = [SELECT Id, Price__c FROM Item__c];

    List<ItemPurchase.CartItemDTO> cart = new List<ItemPurchase.CartItemDTO>();

    for (Item__c i : items) {
      ItemPurchase.CartItemDTO ci = new ItemPurchase.CartItemDTO();
      ci.itemId = i.Id;
      ci.quantity = 2;
      cart.add(ci);
    }

    Test.startTest();
    Id purchaseId = ItemPurchase.checkout(acc.Id, cart);
    Test.stopTest();

    Purchase__c p = [
      SELECT TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id = :purchaseId
    ];

    System.assertEquals(4, p.TotalItems__c); // 2 + 2
    System.assertEquals(60, p.GrandTotal__c); // (10*2 + 20*2)

    List<PurchaseLine__c> lines = [
      SELECT Id
      FROM PurchaseLine__c
      WHERE PurchaseId__c = :purchaseId
    ];

    System.assertEquals(2, lines.size());
  }
}
