chorus.views.ProjectStatus = chorus.views.Base.extend({
    constructorName: "ProjectStatus",
    templateName: "project_status",

    events: {
        "click .edit_project_status": 'launchEditProjectStatusDialog'
    },

    setup: function () {
        if (this.model.get('latestStatusChangeActivity')) {
            var activity = new chorus.models.Activity(this.model.get('latestStatusChangeActivity'));
            this.statusChangeActivityView = new chorus.views.Activity({model: activity, isReadOnly: true});
        }
    },

    postRender: function () { this.styleTooltip(); },

    additionalContext: function () {
        return {
            projectStatusKey: 'workspace.project.status.' + this.model.get('projectStatus'),
            statusReason: this.model.get('projectStatusReason'),
            milestoneProgress: this.model.milestoneProgress()
        };
    },

    launchEditProjectStatusDialog: function(e) {
        e && e.preventDefault();
        new chorus.dialogs.EditProjectStatus({ model: this.model }).launchModal();
    },


    styleTooltip: function () {
        // reassign the offset function so that when qtip calls it, qtip correctly positions the tooltips
        // with regard to the fixed-height header.
        var viewport = $(window);
        viewport.offset = function () {
            return { left: 0, top: $("#header").height() };
        };

        var tooltipOptions = {
            position: {
                viewport: viewport,
                my: "bottom right",
                at: "top center"
            },
            style: { classes: "tooltip-white" }
        };

        if (this.statusChangeActivityView) {
            _.extend(tooltipOptions, {content: $(this.statusChangeActivityView.render().el)});
        }

        this.$('.status_reason').qtip(tooltipOptions);
    }
});