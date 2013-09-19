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
            stateKey: 'workspace.project.milestones.states.' + this.model.get('state')
        };
    },

    postRender: function() {
        this.$(".loading_spinner").startLoading(null, {color: '#959595'});
    }
});