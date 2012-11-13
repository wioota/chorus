window.fixtureDefinitions = {
    sandbox: { unique: [ "id", "workspaceId", "instanceId", "schemaId", "databaseId" ] },

    csvImport: { model: "CSVImport" },

    config: {},

    activity: {
        unique: [ "id" ],

        children: {
            provisioningSuccess: {},
            provisioningFail:    {},
            addHdfsPatternAsExtTable: {},
            addHdfsDirectoryAsExtTable: {}
        }
    },

    workspaceDataset: {
        derived: {
            id: function(a) {
                return a.id;
            }
        },

        children: {
            sourceTable:   {},
            sourceView:    {},
            sandboxTable:  {},
            sandboxView:   {},
            chorusView:    {},
            chorusViewSearchResult: {},
            externalTable: {}
        }
    },

    test: {
        model:   "User",
        unique:  [ "id" ],

        children: {
            noOverrides: {},
            withOverrides: { model: "Workspace" }
        }
    }
};

window.rspecFixtureDefinitions = {
    comment: { model: "Comment", unique: ['id'] },
    csvImport: {  model: "CSVImport" },
    user:    { unique: [ "id" ] },
    userWithErrors: { model:'User' },
    userSet: { unique: [ "id" ] },
    kaggleUserSet: { unique: ["id"] },

    workspaceDataset: {
        unique: ["id"],
        children: {
            chorusView: {
                model: 'ChorusView'
            },
            datasetTable: {},
            datasetView: {},
            sourceTable: {},
            sourceView: {}
        }
    },

    databaseColumnSet: {},

    datasetImportScheduleSet: {},

    datasetImportSet: {
    },

    csvImportSet: {
        collection: "DatasetImportSet"
    },

    schema:    { unique: [ "id", "database.id", "database.instance.id" ] },
    schemaSet: { unique: [ "id" ] },

    workspace:    { unique: [ "id" ] },
    workspaceSet: { unique: [ "id" ] },

    workfile: {
        unique: [ "id" ],
        children: {
            sql: {},
            binary: {},
            image: {},
            text: {},
            tableau: {}
        }
    },
    workfileSet: {},
    workfileVersionSet: {},
    workfileVersion: { unique: ['id']},
    draft: {},
    provisioning: {},

    config: {},

    hadoopInstance: { unique: ["id"] },

    gnipInstance: { unique: ["id"] },

    image: {},

    gpdbInstance: { unique: [ "id" ] },
    database: { unique: ["id"] },

    instanceAccount: { unique: ["id"] },
    instanceAccountSet: {},

    instanceDetails: {
        model: 'InstanceUsage'
    },
    instanceDetailsWithoutPermission: {
        model: 'InstanceUsage'
    },

    forbiddenInstance: {},

    activity: {
        unique: [ "id" ],

        children :{
            greenplumInstanceCreated: {},
            gnipInstanceCreated: {},
            gnipStreamImportCreated: {},
            gnipStreamImportSuccess: {},
            gnipStreamImportFailed: {},
            auroraInstanceProvisioned: {},
            auroraInstanceProvisioningFailed: {},
            greenplumInstanceChangedOwner: {},
            hadoopInstanceCreated: {},
            greenplumInstanceChangedName: {},
            hadoopInstanceChangedName: {},
            publicWorkspaceCreated: {},
            privateWorkspaceCreated: {},
            workspaceMakePublic: {},
            workspaceMakePrivate: {},
            workspaceArchived: {},
            workspaceUnarchived: {},
            workfileCreated: {},
            sourceTableCreated: {},
            userCreated: {},
            sandboxAdded: {},
            noteOnGnipInstanceCreated: {},
            noteOnGreenplumInstanceCreated: {},
            noteOnHadoopInstanceCreated: {},
            insightOnGreenplumInstance: {},
            hdfsExternalTableCreated: {},
            fileImportCreated: {},
            fileImportFailed: {},
            fileImportSuccess: {},
            datasetImportCreated:{},
            datasetImportFailed: {},
            datasetImportSuccess: {},
            noteOnHdfsFileCreated: {},
            noteOnWorkspaceCreated: {},
            noteOnDatasetCreated: {},
            noteOnWorkspaceDatasetCreated: {},
            noteOnWorkfileCreated: {},
            membersAdded: {},
            workfileUpgradedVersion: {},
            workfileVersionDeleted: {},
            chorusViewCreatedFromDataset: {},
            chorusViewCreatedFromWorkfile: {},
            chorusViewChanged: {},
            workspaceChangeName: {},
            tableauWorkbookPublished: {},
            tableauWorkfileCreated: {},
            viewCreated: {},
            importScheduleUpdated: {},
            importScheduleDeleted: {},
            workspaceDeleted: {}
        }
    },

    notificationSet: {},

    searchResult : {},
    typeAheadSearchResult : {},
    emptySearchResult : {
        model: "SearchResult"
    },
    searchResultInWorkspace : {
        model: "SearchResult"
    },
    searchResultInWorkspaceWithEntityTypeWorkfile : {
        model: "SearchResult"
    },
    searchResultWithEntityTypeUser : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnInstanceNote : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnWorkspaceNote : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnWorkfileNote : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnDatasetNote : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnHdfsNote : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnHadoopNote : {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnWorkspaceDatasetNote : {
        model: "SearchResult"
    },

    frequencyTask: {},
    frequencyTaskWithErrors: {
        model: 'FrequencyTask'
    },
    heatmapTask: {},
    boxplotTask: {},
    timeseriesTask: {},
    histogramTask: {},

    dataset: { unique: [ "id" ] },
    dataPreviewTaskResults: {
        model: "DataPreviewTask"
    },
    datasetStatisticsTable: {
        model: "DatasetStatistics"
    },
    datasetStatisticsView: {
        model: "DatasetStatistics"
    },

    schemaFunctionSet: {},

    hdfsFile: {  unique: ["id"], model: "HdfsEntry" },
    hdfsDir: {  unique: ["id"], model: "HdfsEntry" },

    workfileExecutionResults: {
        model: "WorkfileExecutionTask"
    },

    workfileExecutionResultsWithWarning: {
        model: "WorkfileExecutionTask"
    },

    workfileExecutionResultsEmpty: {
        model: "WorkfileExecutionTask"
    },

    workfileExecutionError: {
        model: "WorkfileExecutionTask"
    }
};

