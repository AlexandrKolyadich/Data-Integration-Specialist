trigger ProjectTrigger on Project__c (after update) {
    BillingCalloutService.callBillingService((List<Project__c>)Trigger.new, (Map<Id,Project__c>)Trigger.oldMap);
    System.debug('fdffd');
}