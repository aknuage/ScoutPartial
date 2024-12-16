/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 09-24-2024
 * @last modified by  : NuAge - JP
**/
public with sharing class ProjectTeamController {
    static final List<String> EXTERNAL_PROFILES = new List<String> {'Land Agent', 'External Project Team User'};

    public static void projectTeam_insert(List<Project_Team__c> projectTeams){
        Set<Id> userIds = new Set<Id>();
        for(Project_Team__c pt: projectTeams){
            userIds.add(pt.User__c);
        }

        List<User> users = [SELECT Id, Profile.Name, UserRole.Name  FROM User WHERE Id IN :userIds];

        Map<Id, String> userToProfile = new Map<Id, String>();
        for(User user: users){
            userToProfile.put(user.Id, user.Profile.Name);
        }

        List<Project__c> projects = new List<Project__c>();
        List<Project__share> projectShareRecords = new List<Project__share>();
        List<Project_Team__c> externalProjectTeams = new List<Project_Team__c>();
        List<Project_Team__c> landAgentProjectTeams = new List<Project_Team__c>();

        for(Project_Team__c pt: projectTeams){
            if(pt.Role__c == 'Primary Developer'){
                Project__c project = new Project__c(Id = pt.Project__c, Primary_Developer__c = pt.User__c, Primary_Developer_is_set__c = true);
                projects.add(project);
            } else if(pt.Role__c == 'Secondary Developer'){
                Project__c project = new Project__c(Id = pt.Project__c,Secondary_Developer__c = pt.User__c);
                projects.add(project);
            } else if(pt.Role__c == 'Director Lead'){
                Project__c project = new Project__c(Id = pt.Project__c, Director_Lead__c = pt.User__c,Primary_Developer_is_set__c = true);
                projects.add(project);
            } else if(pt.Role__c == 'Land Agent' && userToProfile.get(pt.User__c) == 'Land Agent'){
                // Project Team role 
                System.debug('Land agent added to project team: ' + pt.Name);
                landAgentProjectTeams.add(pt);        
                Project__c project = new Project__c(
                    Id = pt.Project__c, External_Doc_Prep_is_set__c = true
                );
                projects.add(project);
            } else if(pt.Role__c == 'External Doc Prep' && EXTERNAL_PROFILES.contains(userToProfile.get(pt.User__c))){
                Project__c project = new Project__c(
                    Id = pt.Project__c,
                    External_Doc_Prep_is_set__c = true
                );
                projects.add(project);
                externalProjectTeams.add(pt);
            } else if(pt.Role__c == 'External Title Specialist' && EXTERNAL_PROFILES.contains(userToProfile.get(pt.User__c))){
                Project__c project = new Project__c(
                    Id = pt.Project__c,
                    External_Title_Specialist_is_set__c = true
                );
                projects.add(project);
                externalProjectTeams.add(pt);
            }
        }
        
        update projects;

        // insertExternal
        if(externalProjectTeams.size() > 0) shareExternal(externalProjectTeams, userToProfile);
        if(landAgentProjectTeams.size() > 0){
            projectTeam_insertLandAgentBatchClass gdfc = new projectTeam_insertLandAgentBatchClass();
            gdfc.projectTeams = landAgentProjectTeams;
            Database.executeBatch(gdfc, 1);
        }
    }

    @testVisible
    private static void shareExternal(List<Project_Team__c> projectTeams, Map<Id, String> userToProfile){
        List<Project__share> projectShareRecords = new List<Project__share>();
        Set<Id> projectIds = new Set<Id>();
        List<Project_Team__c> projectTeamRecords = new List<Project_Team__c>();
        System.debug('projectTeamRecords.size(): ' + projectTeams.size());
        
        System.debug('user: ' + [SELECT Name FROM User WHERE Id = :projectTeams[0].User__c]);
        
        for(Project_Team__c pt: projectTeams){
            Project__share projectShare = new Project__share(
                AccessLevel = 'Edit',
                ParentId = pt.Project__c,
                RowCause = 'Project_Team_Member_access__c',
                UserOrGroupId = pt.User__c
            );
            projectShareRecords.add(projectShare);

            projectIds.add(pt.Project__c);
            projectTeamRecords.add(pt);

            projectTeam_createBatchClass gdfc = new projectTeam_createBatchClass();
            gdfc.projectId = pt.Project__c;
            gdfc.userId = pt.User__c;
            Database.executeBatch(gdfc, 25);

            if (Test.isRunningTest()) {
                for (Project__Share share : projectShareRecords) {
                    share.Id = null; // Ensure no Id is set
                }
                
            }
            if(projectShareRecords.size() > 0) insert projectShareRecords;
    
        }

        // List<Account_Project__c> accountProjects = [SELECT Id, Name FROM Account_Project__c WHERE Project__c IN :projectId];

        // for(Project_Team__c pt: projectTeamRecords){
        //     // Call the batch class
        //     // userId
        //     // projectId
        //     projectTeam_createBatchClass gdfc = new projectTeam_createBatchClass();
        //     gdfc.projectId = pt.Project__c;
        //     gdfc.userId = pt.User__c;
        //     Database.executeBatch(gdfc, 25);
        // }
        // if(userToProfile.get(project.User__c) == 'External Project Team User'){
        //     Project__share projectShare = new Project__share(
        //         AccessLevel = 'Edit',
        //         ParentId = pt.Project__c,
        //         RowCause = 'Project_Team_Member_access__c',
        //         UserOrGroupId = pt.User__c
        //     );

        //     insert projectShare;

        //     List<
        // }
    }

    public static void projectTeam_delete(List<Project_Team__c> projectTeams){
        Set<Id> userIds = new Set<Id>();
        for(Project_Team__c pt: projectTeams){
            userIds.add(pt.User__c);
        }

        List<User> users = [SELECT Id, Profile.Name, UserRole.Name  FROM User WHERE Id IN :userIds];

        Map<Id, String> userToProfile = new Map<Id, String>();
        for(User user: users){
            userToProfile.put(user.Id, user.Profile.Name);
        }

        List<Project__c> projects = new List<Project__c>();
        List<Project__share> projectShareRecords = new List<Project__share>();

        List<Project_Team__c> externalProjectTeams = new List<Project_Team__c>();
        List<Project_Team__c> landAgentProjectTeams = new List<Project_Team__c>();
        for(Project_Team__c pt: projectTeams){
            if(pt.Role__c == 'Primary Developer'){
                Project__c project = new Project__c(Id = pt.Project__c, Primary_Developer__c = '', Primary_Developer_is_set__c = false);
                projects.add(project);
            } else if(pt.Role__c == 'Secondary Developer'){
                Project__c project = new Project__c(Id = pt.Project__c,Secondary_Developer__c = '');
                projects.add(project);
            } else if(pt.Role__c == 'Director Lead'){
                Project__c project = new Project__c(Id = pt.Project__c,Director_Lead__c = '',Primary_Developer_is_set__c = false);
                projects.add(project);
            } else if(pt.Role__c == 'Land Agent' && userToProfile.get(pt.User__c) == 'Land Agent'){
                Project__c project = new Project__c(Id = pt.Project__c, External_Title_Specialist_is_set__c = false);
                projects.add(project);
                landAgentProjectTeams.add(pt);
                System.debug('land agent project team: ' + JSON.serializePretty(landAgentProjectTeams));
                // Delete project share records here - I need to batch these out
                // Project__share projectShare = new Project__share(
                //     AccessLevel = 'Edit',
                //     ParentId = pt.Project__c,
                //     RowCause = 'Project_Team_Member_access__c',
                //     UserOrGroupId = pt.User__c
                // );

                // projectShareRecords.add(projectShare);                
            } 
            else if(pt.Role__c == 'External Doc Prep' && EXTERNAL_PROFILES.contains(userToProfile.get(pt.User__c))){
                Project__c project = new Project__c(
                    Id = pt.Project__c,
                    External_Doc_Prep_is_set__c = false
                );
                projects.add(project);

                externalProjectTeams.add(pt);

            } // deleteExternal();
            else if(pt.Role__c == 'External Title Specialist' && EXTERNAL_PROFILES.contains(userToProfile.get(pt.User__c))){
                    Project__c project = new Project__c(
                    Id = pt.Project__c,
                    External_Title_Specialist_is_set__c = false
                );
                projects.add(project);

                externalProjectTeams.add(pt);
            }
        }

        update projects;

        if(landAgentProjectTeams.size() > 0){
            projectTeam_deleteLandAgentBatchClass gdfc = new projectTeam_deleteLandAgentBatchClass();
            gdfc.projectTeams = landAgentProjectTeams;
            Database.executeBatch(gdfc, 1);
        }
        // deleteExternal
        if(externalProjectTeams.size() > 0) deleteExternal(externalProjectTeams, userToProfile);

        // if(landAgentProjectTeams.size() > 0){
        //     projectTeam_deleteLandAgentBatchClass gdfc = new projectTeam_deleteLandAgentBatchClass();
        //     gdfc.projectTeams = landAgentProjectTeams;
        //     Database.executeBatch(gdfc, 1);
        // }
    }

    @testVisible
    private static void deleteExternal(List<Project_Team__c> projectTeams, Map<Id, String> userToProfile){
        List<Project__share> projectShareRecords = new List<Project__share>();
        Set<Id> projectId = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        for(Project_Team__c pt: projectTeams){
            projectId.add(pt.Project__c);
            userIds.add(pt.User__c);

            projectTeam_deleteBatchClass gdfc = new projectTeam_deleteBatchClass();
            gdfc.projectId = pt.Project__c;
            gdfc.userId = pt.User__c;
            Database.executeBatch(gdfc, 25);
        }

        // List<Project__share> projectShares =[SELECT Id, UserOrGroupId, ParentId FROM  Project__share WHERE UserOrGroupId IN: userIds AND ParentId IN: projectId];

        // Map<Id, Map<Id, List<Project__share>>> userToProjectToShareRecord = new Map<Id, Map<Id, List<Project__share>>>();
        // for(Project__share ps: projectShares){
        //     if(!userToProjectToShareRecord.containsKey(ps.UserOrGroupId)){
        //         userToProjectToShareRecord.put(ps.UserOrGroupId, new Map<Id, List<Project__share>>());
        //     }
        //     if(!userToProjectToShareRecord.get(ps.UserOrGroupId).containsKey(ps.ParentId)){
        //         userToProjectToShareRecord.get(ps.UserOrGroupId).put(ps.ParentId, new List<Project__share>());
        //     }

        //     userToProjectToShareRecord.get(ps.UserOrGroupId).get(ps.ParentId).add(ps);
        // }


        // List<Project__share> projectSharesToDelete = new List<Project__share>();
        // for(Project_Team__c pt: projectTeams){
        //     if(userToProfile.get(pt.User__c) != 'System Administrator' || userToProfile.get(pt.User__c) != 'Scout Team' || userToProfile.get(pt.User__c) != 'Corporate User'){
        //         // projectId.add(pt.Project__c);
        //         List<Project__share> deleteProjectShares = userToProjectToShareRecord.get(pt.User__c).get(pt.Project__c);

        //         for(Project__share ps: deleteProjectShares){
        //             projectSharesToDelete.add(ps);
        //         }
        //     }
        // }

        // if(projectSharesToDelete.size() > 0) delete projectSharesToDelete;
    }

    public static void projectTeam_update(List<Project_Team__c> projectTeams, map<Id, Project_Team__c> oldMap){
        Set<Id> userIds = new Set<Id>();
        for(Project_Team__c pt: projectTeams){
            userIds.add(pt.User__c);
        }

        List<User> users = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id IN :userIds];

        Map<Id, String> userToProfile = new Map<Id, String>();

        for(User user: users){
            userToProfile.put(user.Id, user.Profile.Name);
        }

        Set<Id> oldUserIds = new Set<Id>();
        for(Project_Team__c pt: oldMap.values()){
            oldUserIds.add(pt.User__c);
        }

        List<User> oldUsers = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id IN :oldUserIds];

        Map<Id, String> oldUserToProfile = new Map<Id, String>();
        for(User user: oldUsers){
            oldUserToProfile.put(user.Id, user.Profile.Name);
        }

        List<Project__c> projects = new List<Project__c>();
        List<Project__share> projectShareRecords = new List<Project__share>();
        List<Project_Team__c> externalProjectTeams = new List<Project_Team__c>();
        List<Project_Team__c> landAgentProjectTeams = new List<Project_Team__c>();
        List<Project_Team__c> deleteProjectTeams = new List<Project_Team__c>();

        for(Project_Team__c pt: projectTeams){
            if(pt.Role__c == 'Primary Developer'){
                Project__c project = new Project__c(Id = pt.Project__c,Primary_Developer__c = pt.User__c,Primary_Developer_is_set__c = true);
                deleteProjectTeams.add(oldMap.get(pt.Id));
                projects.add(project);
            } else if(pt.Role__c == 'Secondary Developer'){
                Project__c project = new Project__c(Id = pt.Project__c, Secondary_Developer__c = pt.User__c);
                deleteProjectTeams.add(oldMap.get(pt.Id));
                projects.add(project);
            } else if(pt.Role__c == 'Director Lead'){
                Project__c project = new Project__c(Id = pt.Project__c, Director_Lead__c = pt.User__c, Primary_Developer_is_set__c = true);
                deleteProjectTeams.add(oldMap.get(pt.Id));
                projects.add(project);
            } else if(pt.Role__c == 'Land Agent' && userToProfile.get(pt.User__c) == 'Land Agent'){
                Project__c project = new Project__c(Id = pt.Project__c,External_Title_Specialist_is_set__c = true);
                deleteProjectTeams.add(oldMap.get(pt.Id));
                projects.add(project);
                landAgentProjectTeams.add(pt);             
            } else if(pt.Role__c == 'External Doc Prep' && EXTERNAL_PROFILES.contains(userToProfile.get(pt.User__c))){
                Project__c project = new Project__c(Id = pt.Project__c,External_Doc_Prep_is_set__c = true);
                deleteProjectTeams.add(oldMap.get(pt.Id));
                projects.add(project);
                externalProjectTeams.add(pt);
            } else if(pt.Role__c == 'External Title Specialist' && EXTERNAL_PROFILES.contains(userToProfile.get(pt.User__c))){
                Project__c project = new Project__c(Id = pt.Project__c,External_Title_Specialist_is_set__c = true);
                deleteProjectTeams.add(oldMap.get(pt.Id));
                projects.add(project);
                externalProjectTeams.add(pt);
            }
        }

        update projects;

        if(deleteProjectTeams.size() > 0) deleteExternal(deleteProjectTeams, oldUserToProfile);

        // deleteExternal
        if(externalProjectTeams.size() > 0) shareExternal_update(externalProjectTeams, oldMap, userToProfile);

        if(landAgentProjectTeams.size() > 0){
            projectTeam_updateLandAgentBatchClass gdfc = new projectTeam_updateLandAgentBatchClass();
            gdfc.projectTeams = landAgentProjectTeams;
            gdfc.newUserId = projectTeams[0].User__c;
            Database.executeBatch(gdfc, 1);
        }
    }

    private static void shareExternal_update(List<Project_Team__c> projectTeams, Map<Id, Project_Team__c> oldProjectTeams,  Map<Id, String> userToProfile){
        List<Project__share> projectShareRecords = new List<Project__share>();
        Set<Id> projectIds = new Set<Id>();
        List<Project_Team__c> projectTeamRecords = new List<Project_Team__c>();

        for(Project_Team__c pt: projectTeams){
            // if(userToProfile.get(pt.User__c) != 'System Administrator' || userToProfile.get(pt.User__c) != 'Scout Team' || userToProfile.get(pt.User__c) != 'Corporate User'){
            if(userToProfile.get(pt.User__c) == 'External Project Team User')
            {
            
                projectIds.add(pt.Project__c);
                projectTeamRecords.add(pt);

                projectTeam_updateBatchClass gdfc = new projectTeam_updateBatchClass();
                gdfc.projectId = pt.Project__c;
                gdfc.userId = oldProjectTeams.get(pt.Id).User__c;
                gdfc.newUserId = pt.User__c;
                Database.executeBatch(gdfc, 500);
            }

            // if(projectShareRecords.size() > 0) insert projectShareRecords;
        }

        // List<Account_Project__c> accountProjects = [SELECT Id, Name FROM Account_Project__c WHERE Project__c IN :projectId];

        // for(Project_Team__c pt: projectTeamRecords){
        //     // Call the batch class
        //     // userId
        //     // projectId
        //     projectTeam_createBatchClass gdfc = new projectTeam_createBatchClass();
        //     gdfc.projectId = pt.Project__c;
        //     gdfc.userId = pt.User__c;
        //     Database.executeBatch(gdfc, 25);
        // }
        // if(userToProfile.get(project.User__c) == 'External Project Team User'){
        //     Project__share projectShare = new Project__share(
        //         AccessLevel = 'Edit',
        //         ParentId = pt.Project__c,
        //         RowCause = 'Project_Team_Member_access__c',
        //         UserOrGroupId = pt.User__c
        //     );

        //     insert projectShare;

        //     List<
        // }
    }

}