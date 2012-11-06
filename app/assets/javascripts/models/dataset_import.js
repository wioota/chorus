chorus.models.DatasetImport = chorus.models.Base.extend({
    constructorName: "DatasetImport",
    urlTemplate: "workspaces/{{workspaceId}}/datasets/{{datasetId}}/imports",

    declareValidations: function(newAttrs) {
        if (newAttrs.newTable == "true") {
            this.requirePattern("toTable", chorus.ValidationRegexes.ChorusIdentifier64(), newAttrs, 'import.validation.toTable.required');
        }

        this.requirePattern("truncate", chorus.ValidationRegexes.Boolean(), newAttrs);
        this.requirePattern("newTable", chorus.ValidationRegexes.Boolean(), newAttrs);

        if (newAttrs.useLimitRows) {
            this.requirePositiveInteger("sampleCount", newAttrs, 'import.validation.sampleCount.positive');
        }

        if (newAttrs.isActive) {
            if (newAttrs.scheduleStartTime > newAttrs.scheduleEndTime) {
                this.setValidationError("year", "import.schedule.error.start_date_must_precede_end_date", null, newAttrs);
            }
        }
    },

    destination: function() {
        return new chorus.models.WorkspaceDataset({
            id: this.get("destinationDatasetId"),
            objectName: this.get("toTable"),
            workspace: {id: this.get("workspaceId")}
        });
    },

    nextDestination: function() {
        return new chorus.models.WorkspaceDataset({
            id: this.get("destinationDatasetId"),
            objectName: this.get("toTable"),
            workspace: {id: this.get("workspaceId")}
        });
    },

    lastDestination: function() {
        return new chorus.models.WorkspaceDataset({
            id: this.get('destinationDatasetId'),
            objectName: this.get("toTable"),
            workspace: {id: this.get("workspaceId")}
        });
    },

    importSource: function() {
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
