trigger PurchaseLineTrigger on PurchaseLine__c(
  after insert,
  after update,
  after delete,
  after undelete
) {
  Set<Id> purchaseIds = new Set<Id>();

  if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
    for (PurchaseLine__c pl : Trigger.new) {
      if (pl.PurchaseId__c != null) {
        purchaseIds.add(pl.PurchaseId__c);
      }
    }
  }
  if (Trigger.isDelete) {
    for (PurchaseLine__c pl : Trigger.old) {
      if (pl.PurchaseId__c != null) {
        purchaseIds.add(pl.PurchaseId__c);
      }
    }
  }
  if (purchaseIds.isEmpty())
    return;

  Map<Id, Integer> totalItems = new Map<Id, Integer>();
  Map<Id, Decimal> grandTotals = new Map<Id, Decimal>();

  for (PurchaseLine__c pl : [
    SELECT PurchaseId__c, Amount__c, UnitCost__c
    FROM PurchaseLine__c
    WHERE PurchaseId__c IN :purchaseIds
  ]) {
    Integer qty = pl.Amount__c == null ? 0 : pl.Amount__c.intValue();
    Decimal lineTotal = qty * pl.UnitCost__c;

    totalItems.put(
      pl.PurchaseId__c,
      (totalItems.get(pl.PurchaseId__c) == null
        ? 0
        : totalItems.get(pl.PurchaseId__c)) + qty
    );

    grandTotals.put(
      pl.PurchaseId__c,
      (grandTotals.get(pl.PurchaseId__c) == null
        ? 0
        : grandTotals.get(pl.PurchaseId__c)) + lineTotal
    );
  }

  Map<Id, Purchase__c> purchaseMap = new Map<Id, Purchase__c>(
    [
      SELECT Id, TotalItems__c, GrandTotal__c
      FROM Purchase__c
      WHERE Id IN :purchaseIds
    ]
  );

  List<Purchase__c> updates = new List<Purchase__c>();

  for (Id pid : purchaseIds) {
    Integer newTotalItems = totalItems.containsKey(pid)
      ? totalItems.get(pid)
      : 0;
    Decimal newGrandTotal = grandTotals.containsKey(pid)
      ? grandTotals.get(pid)
      : 0;

    Purchase__c p = purchaseMap.get(pid);

    if (p.TotalItems__c != newTotalItems || p.GrandTotal__c != newGrandTotal) {
      updates.add(
        new Purchase__c(
          Id = pid,
          TotalItems__c = newTotalItems,
          GrandTotal__c = newGrandTotal
        )
      );
    }
  }

  if (!updates.isEmpty()) {
    update updates;
  }
}
