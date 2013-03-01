chorus.models.WorkspaceImport = chorus.models.Base.extend({
    constructorName: "WorkspaceImport",
    urlTemplate: "workspaces/{{workspaceId}}/imports",
    parameterWrapper: 'dataset_import',

    declareValidations: function(newAttrs) {
        if (newAttrs.newTable === "true") {
            this.requirePattern("toTable", chorus.ValidationRegexes.ChorusIdentifier64(), newAttrs, 'import.validation.toTable.required');
        }

        this.requirePattern("truncate", chorus.ValidationRegexes.Boolean(), newAttrs);
        this.requirePattern("newTable", chorus.ValidationRegexes.Boolean(), newAttrs);

        if (newAttrs.useLimitRows) {
            this.requirePositiveInteger("sampleCount", newAttrs, 'import.validation.sampleCount.positive');
        }
    },

    destination: function() {
        return new chorus.models.WorkspaceDataset({
            id: this.get("destinationDatasetId"),
            objectName: this.get("toTable"),
            workspace: {id: this.get("workspaceId")}
        });
    },

    source: function() {
        return new chorus.models.WorkspaceDataset({
            id: this.get('sourceDatasetId'),
            objectName: this.get('sourceDatasetName'),
            workspace: { id: this.get("workspaceId") }
        });
    },

    isInProgress: function() {
        return this.get('startedStamp') && !this.get('completedStamp');
    }
});
