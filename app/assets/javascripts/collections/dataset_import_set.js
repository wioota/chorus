chorus.collections.DatasetImportSet = chorus.collections.Base.extend({
    constructorName: "DatasetImportSet",
    model:chorus.models.DatasetImport,
    urlTemplate: "workspaces/{{workspaceId}}/datasets/{{datasetId}}/imports"
});