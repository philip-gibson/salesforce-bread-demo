/**
 * AccountsTrigger
 *
 * Thin trigger per Apex Enterprise Patterns (extends fflib_SObjectDomain).
 * Contains NO logic. All business & trigger logic lives in the Accounts domain class.
 */
trigger AccountsTrigger on Account (before insert, before update) {
    fflib_SObjectDomain.triggerHandler(Accounts.class);
}
