window.rspecFixtureDefinitions = {
    activity: {
        unique: [ "id" ],

        children: {
            chorusViewChanged: {},
            chorusViewCreatedFromDataset: {},
            chorusViewCreatedFromWorkfile: {},
            datasetImportCreated: {},
            datasetImportFailed: {},
            datasetImportFailedWithModelErrors: {},
            datasetImportSuccess: {},
            fileImportCreated: {},
            fileImportFailed: {},
            fileImportSuccess: {},
            gnipInstanceCreated: {},
            gnipStreamImportCreated: {},
            gnipStreamImportFailed: {},
            gnipStreamImportSuccess: {},
            greenplumInstanceChangedName: {},
            greenplumInstanceChangedOwner: {},
            greenplumInstanceCreated: {},
            hadoopInstanceCreated: {},
            hadoopInstanceChangedName: {},
            hdfsFileExtTableCreated: {},
            hdfsDirectoryExtTableCreated: {},
            hdfsPatternExtTableCreated: {},
            importScheduleDeleted: {},
            importScheduleUpdated: {},
            insightOnGreenplumInstance: {},
            membersAdded: {},
            noteOnDatasetCreated: {},
            noteOnGnipInstanceCreated: {},
            noteOnGreenplumInstanceCreated: {},
            noteOnHadoopInstanceCreated: {},
            noteOnHdfsFileCreated: {},
            noteOnWorkfileCreated: {},
            noteOnWorkspaceCreated: {},
            noteOnWorkspaceDatasetCreated: {},
            privateWorkspaceCreated: {},
            publicWorkspaceCreated: {},
            sandboxAdded: {},
            sourceTableCreated: {},
            tableauWorkbookPublished: {},
            tableauWorkfileCreated: {},
            userCreated: {},
            viewCreated: {},
            workfileCreated: {},
            workfileUpgradedVersion: {},
            workfileVersionDeleted: {},
            workspaceChangeName: {},
            workspaceDeleted: {},
            workspaceMakePublic: {},
            workspaceMakePrivate: {},
            workspaceArchived: {},
            workspaceUnarchived: {}
        }
    },

    boxplotTask: {},

    comment: { model: "Comment", unique: ['id'] },

    config: {},

    csvImport: {  model: "CSVImport" },

    csvImportSet: {
        collection: "DatasetImportSet"
    },

    database: { unique: ["id"] },

    databaseColumn: {},

    databaseColumnSet: {},

    dataPreviewTaskResults: {
        model: "DataPreviewTask"
    },

    dataset: { unique: [ "id" ] },

    datasetImportScheduleSet: {},

    datasetImportSet: {},

    datasetStatisticsTable: {
        model: "DatasetStatistics"
    },

    datasetStatisticsView: {
        model: "DatasetStatistics"
    },

    draft: {},

    forbiddenInstance: {},

    frequencyTask: {},

    frequencyTaskWithErrors: {
        model: 'FrequencyTask'
    },

    gnipInstance: { unique: ["id"] },

    gpdbInstance: { unique: [ "id" ] },

    hadoopInstance: { unique: ["id"] },

    heatmapTask: {},

    hdfsEntrySet: {},

    hdfsFile: {  unique: ["id"], model: "HdfsEntry" },

    hdfsDir: {  unique: ["id"], model: "HdfsEntry" },

    histogramTask: {},

    image: {},

    instanceAccount: { unique: ["id"] },

    instanceAccountSet: {},

    instanceDetails: {
        model: 'InstanceUsage'
    },

    instanceDetailsWithoutPermission: {
        model: 'InstanceUsage'
    },

    kaggleUserSet: { unique: ["id"] },

    notification: {
        unique: ["id"]
    },

    notificationSet: {},

    schema: { unique: [ "id", "database.id", "database.instance.id" ] },

    schemaFunctionSet: {},

    schemaSet: { unique: [ "id" ] },

    searchResult: {},

    emptySearchResult: {
        model: "SearchResult"
    },

    searchResultInWorkspace: {
        model: "SearchResult"
    },

    searchResultInWorkspaceWithEntityTypeWorkfile: {
        model: "SearchResult"
    },

    searchResultWithEntityTypeUser: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnInstanceNote: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnWorkspaceNote: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnWorkfileNote: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnDatasetNote: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnHdfsNote: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnHadoopNote: {
        model: "SearchResult"
    },

    searchResultWithAttachmentOnWorkspaceDatasetNote: {
        model: "SearchResult"
    },

    tableauWorkbook: {
        unique: [ "id" ]
    },

    tagSet: {

    },

    test: {
        model:   "User",
        unique:  [ "id" ],

        children: {
            noOverrides: {},
            withOverrides: { model: "Workspace" }
        }
    },

    timeseriesTask: {},

    typeAheadSearchResult: {},

    user: { unique: [ "id" ] },

    userSet: { unique: [ "id" ] },

    userWithErrors: { model: 'User' },

    workfile: {
        unique: [ "id" ],
        children: {
            alpine: {
                model: 'AlpineWorkfile'
            },
            sql: {},
            binary: {},
            image: {},
            text: {},
            tableau: {}
        }
    },

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
    },

    workfileSet: {},

    workfileVersionSet: {},

    workfileVersion: { unique: ['id']},

    workspace: { unique: [ "id" ] },

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

    workspaceSet: { unique: [ "id" ] }
};
