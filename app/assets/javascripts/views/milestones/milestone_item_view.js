chorus.views.MilestoneItem = chorus.views.Base.extend({
    constructorName: "MilestoneItemView",
    templateName: "milestone_item",

    events: {
    },

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
    },

    additionalContext: function () {
        return {
            statusKey: 'workspace.project.milestones.statuses.' + this.model.get('status')
        };
    },

    postRender: function() {
        this.$(".loading_spinner").startLoading(null, {color: '#959595'});
    }
});