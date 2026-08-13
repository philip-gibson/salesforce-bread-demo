/**
 * BreadOrderTrigger
 *
 * Thin trigger per Apex Enterprise Patterns (fflib_SObjectDomain).
 * Contains NO logic. All business logic lives in the BreadOrdersTriggerHandler class.
 */
trigger BreadOrderTrigger on Bread_Order__c (before insert, before update, after insert, after update) {
    fflib_SObjectDomain.triggerHandler(BreadOrdersTriggerHandler.class);
}
