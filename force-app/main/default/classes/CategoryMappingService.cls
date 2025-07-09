public with sharing class CategoryMappingService {
@AuraEnabled(cacheable=true)
public static Map<String, String> getSubToCategoryMap() {
    Map<String, String> result = new Map<String, String>();

    for (Category__c cat : [
        SELECT Category__c, SubCategory__c
        FROM Category__c
        WHERE Category__c != null AND SubCategory__c != null
    ]) {
        result.put(cat.SubCategory__c, cat.Category__c);
    }

    return result;
}
}