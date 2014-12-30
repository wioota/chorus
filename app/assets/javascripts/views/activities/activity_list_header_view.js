chorus.views.ActivityListHeader = chorus.views.Base.extend({
    constructorName: "ActivityListHeaderView",
    templateName : "activity_list_header",
    additionalClass: 'list_header',
    persistent: true,

    events: {
        "change .activities_filter": "onFilterChange"
    },


    setup: function() {

    	/* jshint ignore:start */
        console.log ("ActivityListHeader > setup");
        /* jshint ignore:end */
        
        if(!this.collection) {
            this.collection = this.model.activities();
        }

        this.allTitle = this.options.allTitle;
        this.insightsTitle = this.options.insightsTitle;
    },

    postRender: function() {
        _.defer(_.bind(function () {
            chorus.styleSelect(this.selectElement());
        }, this));
        var value = this.collection.attributes.insights ? "only_insights" : "all_activity";
        this.selectElement().val(value);

    },

//     additionalContext: function() {
//         return {};
//     },

    pickTitle: function() {
        return this.collection.attributes.insights ? this.insightsTitle : this.allTitle;
    },

    reloadCollection: function() {
        this.collection.loaded = false;
        this.collection.reset();
        this.collection.fetch();
        this.render();
    },

    onFilterChange: function(e) {
        e && e.preventDefault();

        this.collection.attributes.insights = this.isInsightsOnly();
        this.reloadCollection();
    },

    isInsightsOnly: function() {
        return this.selectElement().val() === "only_insights";
    },

    selectElement: function() {
        return this.$("select.activities_filter");
    }
});
