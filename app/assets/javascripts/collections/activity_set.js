chorus.collections.ActivitySet = chorus.collections.Base.extend({
    constructorName: "ActivitySet",
    model: chorus.models.Activity,

    setup: function() {
        this.bind("reset", this.reindexErrors);
    },

    reindexErrors: function() {
        _.each(this.models, function(activity) {
            activity.reindexError();
        });
    },

    urlTemplate: function() {
        var url = this.attributes.insights ? 'insights' : this.attributes.url;
        return url;
    },

    urlParams: function() {
        if (this.attributes.insights) {
            if(this.attributes.workspace) {
                return { entityType: 'workspace', workspaceId: this.attributes.workspace.id };
            } else {
                return { entityType: 'dashboard' };
            }
        }
    }
}, {

    forDashboard: function() {
        return new this([], { url: "activities?entity_type=dashboard" });
    },

    forModel: function(model) {
        return new this([], { url: this.urlForModel(model) });
    },

    urlForModel: function(model) {
        var entityId = model.get('id');
        return "activities?entity_type=" + model.entityType + "&entity_id=" + entityId;
    }
});
