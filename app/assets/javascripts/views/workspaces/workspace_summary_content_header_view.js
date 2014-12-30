chorus.views.WorkspaceSummaryContentHeader = chorus.views.Base.extend ({
    constructorName: "WorkspaceSummaryContentHeaderView",
    templateName: "workspace_summary_content_header",
    additionalClass: 'taggable_header',
    useLoadingSection: true,

    subviews: {
        ".tag_box": "tagBox"
    },

    setup: function() {
//         this.model.activities().fetchIfNotLoaded();
//         this.requiredResources.push(this.model);
//         this.listenTo(this.model, "saved", this.updateHeaderAndActivityList);

        this.tagBox = this.options.tagBox;
    },

    additionalContext: function() {
        return {
            title:  this.model.get("name"),
            iconUrl: this.model && this.model.defaultIconUrl(),
            tagBox: this.tagBox
        };
    },

//     updateHeaderAndActivityList: function() {
//         this.resourcesLoaded();
//         this.render();
//     },

    resourcesLoaded : function() {

        this.truncatedSummary = new chorus.views.TruncatedText({model:this.model, attribute:"summary", attributeIsHtmlSafe: true, extraLine: true});

    },

    postRender: function() {
        if(this.model.get("summary")) {
            this.$(".truncated_summary").removeClass("hidden");
        } else {
            this.$(".truncated_summary").addClass("hidden");
        }
    }
});