chorus.collections.DatasetImportScheduleSet = chorus.collections.Base.extend({
    constructorName: "DatasetImportScheduleSet",
    model: chorus.models.DatasetImportSchedule,
    urlTemplate: "workspaces/{{workspaceId}}/datasets/{{datasetId}}/import_schedules"
});