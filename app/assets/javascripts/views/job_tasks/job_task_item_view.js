chorus.views.JobTaskItem = chorus.views.Base.extend({
    constructorName: "JobTaskItemView",
    templateName:"job_task_item",

    events: {
        "click .down_arrow": "moveJobTaskDown",
        "click .up_arrow"  : "moveJobTaskUp"
    },

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
        this.listenTo(this.model, "saved", function() { chorus.page.model.trigger("invalidated"); });
    },

    additionalContext: function () {
        var action = this.model.get("action");
        var collection = this.model.collection;
        return {
            checkable: false,
            url: this.model.showUrl(),
            actionKey: "job_task.action." + action,
            iconUrl: this.iconUrlForType(action),
            firstItem: collection.indexOf(this.model) === 0,
            lastItem: collection.indexOf(this.model) === collection.length - 1
        };
    },

    iconUrlForType: function (action) {
        var iconMap = {
            run_work_flow: "/images/jobs/afm-task.png",
            run_sql_file: "/images/workfiles/icon/sql.png",
            import_source_data: "/images/import_icon.png"
        };
        return iconMap[action];
    },

    moveJobTaskDown: function() {
        this.model.save({index: this.model.get("index") + 1}, {wait: true});
    },

    moveJobTaskUp: function() {
        this.model.save({index: this.model.get("index") - 1}, {wait: true});
    }
});
