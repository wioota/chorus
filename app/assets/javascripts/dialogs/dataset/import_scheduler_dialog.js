chorus.dialogs.ImportScheduler = chorus.dialogs.ImportNow.extend({
    constructorName: "ImportSchedulerDialog",
    showSchedule: true,

    resourcesLoaded: function() {
        this.model = this.schedule = this.dataset.importSchedule() || this.model;
        this._super('resourcesLoaded');
    },

    makeModel: function() {
        this.dataset = this.options.dataset;
        this.workspace = this.options.workspace;
        this.model = new chorus.models.DatasetImportSchedule({
            datasetId: this.dataset.get("id"),
            workspaceId: this.dataset.get("workspace").id
        });
    }
});
