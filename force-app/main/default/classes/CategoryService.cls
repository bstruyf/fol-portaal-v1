public with sharing class CategoryService {

    @AuraEnabled(cacheable=true)
    public static List<CategoryWrapper> getAllCategories() {
        List<Category__c> records = [SELECT Id, Category__c, SubCategory__c FROM Category__c];
        Map<String, CategoryWrapper> mapCatToWrapper = new Map<String, CategoryWrapper>();

        for (Category__c rec : records) {
            if (String.isBlank(rec.Category__c) || String.isBlank(rec.SubCategory__c)) continue;

            // Voeg categorie toe als die nog niet bestaat
            if (!mapCatToWrapper.containsKey(rec.Category__c)) {
                mapCatToWrapper.put(rec.Category__c, new CategoryWrapper(rec.Category__c));
            }

            CategoryWrapper wrapper = mapCatToWrapper.get(rec.Category__c);
            wrapper.subcategories.add(new SubCategoryEntry(rec.SubCategory__c, rec.Id));
        }

        return new List<CategoryWrapper>(mapCatToWrapper.values());
    }

    public class CategoryWrapper {
        @AuraEnabled public String category;
        @AuraEnabled public List<SubCategoryEntry> subcategories;

        public CategoryWrapper(String category) {
            this.category = category;
            this.subcategories = new List<SubCategoryEntry>();
        }
    }

    public class SubCategoryEntry {
        @AuraEnabled public String subcategory;
        @AuraEnabled public String id; // dit is het record ID van Category__c

        public SubCategoryEntry(String subcategory, String id) {
            this.subcategory = subcategory;
            this.id = id;
        }
    }
}