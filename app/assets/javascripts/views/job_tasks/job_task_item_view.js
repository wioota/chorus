chorus.views.JobTaskItem = chorus.views.Base.extend({
    constructorName: "JobTaskItemView",
    templateName:"job_task_item",

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
    },

    additionalContext: function () {
        var type = this.model.get("type");
        return {
            draggable: true,
            checkable: false,
            url: this.model.showUrl(),
            typeKey: "job_task.type." + type,
            iconUrl: this.iconUrlForType(type)
        };
    },

    iconUrlForType: function (type) {
        var iconMap = {
            run_work_flow: "/images/workfiles/icon/afm.png",
            run_sql_file: "/images/workfiles/icon/sql.png",
            import_source_data: "/images/import_icon.png"
        };
        return iconMap[type];
    }
});
