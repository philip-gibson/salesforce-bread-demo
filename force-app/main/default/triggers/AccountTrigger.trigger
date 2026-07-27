/**
 * AccountTrigger
 *
 * Thin trigger per Apex Enterprise Patterns (fflib_SObjectDomain).
 * Contains NO logic. All business logic lives in the Accounts domain class.
 */
trigger AccountTrigger on Account (before insert, before update) {
    fflib_SObjectDomain.triggerHandler(Accounts.class);
}
