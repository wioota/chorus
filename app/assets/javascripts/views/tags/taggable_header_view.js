chorus.views.TaggableHeader = chorus.views.Base.extend({
    templateName: "taggable_header",
    constructorName: "TaggableHeaderView",

    subviews: {
        '.tag_box': 'tagBox'
    },

    setup: function () {

        /* jshint ignore:start */
		console.log ("taggable_header_view.js > setup");
        /* jshint ignore:end */
        
        this.tagBox = new chorus.views.TagBox({
            model: this.model
        });
    },

    additionalContext: function () {
        return {
            iconUrl: this.model.iconUrl()
        };
    }
});