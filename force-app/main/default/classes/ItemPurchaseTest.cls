@IsTest
public class ItemPurchaseTest {
  @TestSetup
  static void setupData() {
    Account acc = new Account(
      Name = 'Test Account',
      AccountNumber = '12345',
      Industry = 'Chemicals'
    );
    insert acc;

    Item__c item = new Item__c(
      Name = 'Test Item',
      Description__c = 'Test Description',
      Family__c = 'Family 1',
      Type__c = 'Type 1',
      Price__c = 100
    );
    insert item;

    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];

    User u = new User(
      Alias = 'mgr',
      Email = 'manager@test.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Manager',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'Europe/London',
      UserName = 'manager' + System.currentTimeMillis() + '@test.com',
      IsManager__c = true
    );
    insert u;
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
    List<Item__c> items = ItemPurchase.getItem('Family 1', 'Type 1', 'Test');
    Test.stopTest();

    System.assertEquals(1, items.size());
    System.assertEquals('Test Item', items[0].Name);
  }

  @IsTest
  static void testGetItemCount() {
    Test.startTest();
    Integer count = ItemPurchase.getItemCount('Family 1', 'Type 1', 'Test');
    Test.stopTest();

    System.assertEquals(1, count);
  }

  @IsTest
  static void testIsManager() {
    User u = [SELECT Id FROM User WHERE IsManager__c = TRUE LIMIT 1];
    System.runAs(u) {
      Test.startTest();
      Boolean result = ItemPurchase.isManager();
      Test.stopTest();

      System.assertEquals(true, result);
    }
  }

  @IsTest
  static void testCreateItemWithImage() {
    Test.setMock(HttpCalloutMock.class, new UnsplashMock());

    Item__c item = new Item__c(
      Name = 'API Item',
      Description__c = 'Created via API',
      Family__c = 'Family 2',
      Type__c = 'Type 2',
      Price__c = 200
    );

    Test.startTest();
    Id itemId = ItemPurchase.createItemWithImage(item);
    Test.stopTest();

    Item__c insertedItem = [
      SELECT Image__c
      FROM Item__c
      WHERE Id = :itemId
    ];

    System.assertNotEquals(null, insertedItem.Image__c);
  }

  @IsTest
  static void testCheckout() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Item__c item = [SELECT Id FROM Item__c LIMIT 1];

    ItemPurchase.CartItemDTO dto = new ItemPurchase.CartItemDTO();
    dto.itemId = item.Id;
    dto.quantity = 2;

    List<ItemPurchase.CartItemDTO> cart = new List<ItemPurchase.CartItemDTO>{
      dto
    };

    Test.startTest();
    Id purchaseId = ItemPurchase.checkout(acc.Id, cart);
    Test.stopTest();

    System.assertNotEquals(null, purchaseId);

    List<PurchaseLine__c> lines = [
      SELECT Id
      FROM PurchaseLine__c
      WHERE PurchaseId__c = :purchaseId
    ];

    System.assertEquals(1, lines.size());
  }
}
