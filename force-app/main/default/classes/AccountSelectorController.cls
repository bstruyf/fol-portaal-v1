public with sharing class AccountSelectorController {
  @AuraEnabled(cacheable=true)
  public static List<Account> zoekAccounts(String key) {
    String zoekwaarde = '%' + key + '%';
    return [
      SELECT Id, Name, APB_SCN_Number__c, BillingCity
      FROM Account
      WHERE Name LIKE :zoekwaarde
         OR APB_SCN_Number__c LIKE :zoekwaarde
      LIMIT 10
    ];
  }
}