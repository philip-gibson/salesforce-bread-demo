/** Change Salesforce Org Language to English */

/**
 * Use .apex files to store anonymous Apex.
 *
 * You can execute anonymous Apex in VS Code by selecting the apex text and running the command:
 * SFDX: Execute Anonymous Apex with Currently Selected Text
 *
 * You can also execute the entire file by running the command:
 * SFDX: Execute Anonymous Apex with Editor Contents
 */

User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
u.LanguageLocaleKey = 'en_US';
u.LocaleSidKey = 'en_US';
u.TimeZoneSidKey = 'America/Montevideo';
update u;
