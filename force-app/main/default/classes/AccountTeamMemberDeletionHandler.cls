/**
 * Class used for deleting AccountTeamMembers when removing a Project Team Member
 * who owns a child object of the Account from whose access they are revoked.
 * Due to private Account sharing model, the record needs to be assigned to another
 * user who has the necessary access to delete the record.
 * 
 * @author AKelly @ Nuage Experts : March 2025  
 */
public class AccountTeamMemberDeletionHandler {
    public static void deleteAccountTeamMembers(Map<Id, List<sObject>> children, Id revokedUserId) {
        if (children.keySet() == null || children.keySet().isEmpty() || revokedUserId == null) {
            return;
        }

        Id assignToUser;
        Set<Id> accountIds = children.keySet();
        
        // By default, assign child objects to Roxanne
        List<User> assignUsers = [SELECT Id FROM User WHERE Name = 'Roxanne Huffine'];

        if (!assignUsers.isEmpty()) {
            assignToUser = assignUsers[0].Id;
        } else {
            // Fall back to current user
            assignToUser = UserInfo.getUserId();
        }

        // Fetch current AccountShare records for all relevant Accounts
        Map<Id, Set<Id>> accountShareMap = new Map<Id, Set<Id>>();
        for (AccountShare share : [
            SELECT Id, UserOrGroupId, AccountId 
            FROM AccountShare 
            WHERE AccountId IN :accountIds
        ]) {
            if (!accountShareMap.containsKey(share.AccountId)) {
                accountShareMap.put(share.AccountId, new Set<Id>());
            }
            accountShareMap.get(share.AccountId).add(share.UserOrGroupId);
        }

        // Find all Owners of child records who might lose access
        Map<Id, Set<Id>> ownersNeedingAccess = new Map<Id, Set<Id>>();
        List<Contact> consToUpdate = new List<Contact>();
        
        // Process Contacts
        for (Contact c : [
            SELECT OwnerId, AccountId 
            FROM Contact 
            WHERE AccountId IN :accountIds
        ]) {
            if (!accountShareMap.containsKey(c.AccountId) || !accountShareMap.get(c.AccountId).contains(c.OwnerId)) {
                if (!ownersNeedingAccess.containsKey(c.AccountId)) {
                    ownersNeedingAccess.put(c.AccountId, new Set<Id>());
                }
                ownersNeedingAccess.get(c.AccountId).add(c.OwnerId);
            }
            c.OwnerId = assignToUser;
            consToUpdate.add(c);
        }

        update consToUpdate;

        // Process Opportunities
        // for (Opportunity o : [
        //     SELECT OwnerId, AccountId 
        //     FROM Opportunity 
        //     WHERE AccountId IN :accountIds
        // ]) {
        //     if (!accountShareMap.containsKey(o.AccountId) || !accountShareMap.get(o.AccountId).contains(o.OwnerId)) {
        //         if (!ownersNeedingAccess.containsKey(o.AccountId)) {
        //             ownersNeedingAccess.put(o.AccountId, new Set<Id>());
        //         }
        //         ownersNeedingAccess.get(o.AccountId).add(o.OwnerId);
        //     }
        // }

        // Process Cases (if applicable)
        // for (Case c : [
        //     SELECT OwnerId, AccountId 
        //     FROM Case 
        //     WHERE AccountId IN :accountIds
        // ]) {
        //     if (!accountShareMap.containsKey(c.AccountId) || !accountShareMap.get(c.AccountId).contains(c.OwnerId)) {
        //         if (!ownersNeedingAccess.containsKey(c.AccountId)) {
        //             ownersNeedingAccess.put(c.AccountId, new Set<Id>());
        //         }
        //         ownersNeedingAccess.get(c.AccountId).add(c.OwnerId);
        //     }
        // }

        // Process any additional child objects as necessary

        // Create new AccountShare records where necessary
        List<AccountShare> newShares = new List<AccountShare>();
        for (Id accountId : ownersNeedingAccess.keySet()) {
            for (Id ownerId : ownersNeedingAccess.get(accountId)) {
                AccountShare share = new AccountShare();
                share.AccountId = accountId; 
                share.UserOrGroupId = ownerId;
                share.AccountAccessLevel = 'Read'; 
                share.RowCause = 'Manual'; // Ensures it's a manually created share
                newShares.add(share);
            }
        }

        if (!newShares.isEmpty()) insert newShares;

        // Now safely delete the Account Team Members
        List<AccountTeamMember> teamMembersToDelete = [
            SELECT Id FROM AccountTeamMember 
            WHERE AccountId IN :accountIds AND UserId = :revokedUserId
        ];
        
        if (!teamMembersToDelete.isEmpty()) delete teamMembersToDelete;
    }
}
