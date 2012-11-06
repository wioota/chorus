chorus.models.DatasetImportSchedule = chorus.models.Base.extend({
    urlTemplate: "workspaces/{{workspaceId}}/datasets/{{datasetId}}/import_schedules/{{id}}",
    constructorName: 'DatasetImportSchedule',

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

    nextExecutionAt: function() {
        return this.get("nextImportAt")
    },

    hasNextImport: function() {
        return !!this.get("nextImportAt")
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