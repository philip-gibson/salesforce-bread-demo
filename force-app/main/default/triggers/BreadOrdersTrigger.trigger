/**
 * BreadOrdersTrigger
 *
 * Thin trigger per Apex Enterprise Patterns (extends fflib_SObjects implements IBreadOrders).
 * Contains NO logic.
 * All trigger logic lives in the BreadOrdersTriggerHandler class.
 * All business logic lives in the BreadOrders class (Domain).
 */
trigger BreadOrdersTrigger on Bread_Order__c (before insert, before update, after insert, after update) {
    fflib_SObjectDomain.triggerHandler(BreadOrdersTriggerHandler.class);
}
