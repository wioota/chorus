chorus.models.DatasetImportSchedule = chorus.models.Base.extend({
    urlTemplate: "workspaces/{{workspaceId}}/datasets/{{datasetId}}/import_schedules/{{id}}",
    constructorName: 'DatasetImportSchedule',

    declareValidations: function(newAttrs) {
        if (newAttrs.newTable == "true") {
            this.requirePattern("toTable", chorus.ValidationRegexes.ChorusIdentifier64(), newAttrs, 'import.validation.toTable.required');
        }

        this.requirePattern("truncate", chorus.ValidationRegexes.Boolean(), newAttrs);
        this.requirePattern("newTable", chorus.ValidationRegexes.Boolean(), newAttrs);

        if (newAttrs.useLimitRows) {
            this.requirePositiveInteger("sampleCount", newAttrs, 'import.validation.sampleCount.positive');
        }

        if (newAttrs.scheduleStartTime > newAttrs.scheduleEndTime) {
            this.setValidationError("year", "import.schedule.error.start_date_must_precede_end_date", null, newAttrs);
        }
    },

    destination: function() {
        return new chorus.models.WorkspaceDataset({
            id: this.get('destinationDatasetId'),
            objectName: this.get("toTable"),
            workspace: {id: this.get("workspaceId")}
        });
    },

    frequency:function () {
        return this.get("frequency") && this.get("frequency").toUpperCase();
    },

    endTime:function () {
        return  this.get("endDate") && Date.parse(this.get("endDate"));
    },

    startTime: function () {
        if (this.get("startDatetime")) {
            return Date.parseFromApi(this.get("startDatetime").split(".")[0]);
        } else {
            return Date.today().set({hour:23});
        }
    }
});