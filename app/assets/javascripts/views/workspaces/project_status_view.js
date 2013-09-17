chorus.views.ProjectStatus = chorus.views.Base.extend({
    constructorName: "ProjectStatus",
    templateName: "project_status",

    events: {
        "click .edit_project_status": 'launchEditProjectStatusDialog'
    },

    postRender: function () {
        var viewport = $(window);
        var top = $("#header").height();
        viewport.offset = function() {
            return { left: 0, top: top };
        };

        this.styleTooltip();
    },

    additionalContext: function () {
        return {
            projectStatusKey: 'workspace.project.status.' + this.model.get('projectStatus'),
            statusReason: this.model.get('projectStatusReason'),
            milestoneProgress: this.model.milestoneProgress()
        };
    },

    launchEditProjectStatusDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.EditProjectStatus({
            model: this.model
        });
        dialog.launchModal();
    },


    styleTooltip: function () {
        // reassign the offset function so that when qtip calls it, qtip correctly positions the tooltips
        // with regard to the fixed-height header.
        var viewport = $(window);
        viewport.offset = function () {
            return { left: 0, top: $("#header").height() };
        };

        $('.status-reason').qtip({
            position: {
                viewport: viewport,
                my: "bottom right",
                at: "top left"
            },
            style: { classes: "tooltip-white" }
        });
    }
});