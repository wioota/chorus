chorus.views.WorkspaceSummaryContentHeader = chorus.views.Base.extend({
    constructorName: "WorkspaceSummaryContentHeaderView",
    templateName: "workspace_summary_content_header",
    useLoadingSection: true,

    subviews: {
        ".truncated_summary": "truncatedSummary",
        ".activity_list_header": "activityListHeader",
        '.tag_box': 'tagBox'
    },

    setup: function() {
        this.model.activities().fetchIfNotLoaded();
        this.requiredResources.push(this.model);
        this.listenTo(this.model, "saved", this.updateHeaderAndActivityList);
        this.tagBox = new chorus.views.TagBox({
            model: this.model,
            workspaceIdForTagLink: this.model.id
        });
    },

    updateHeaderAndActivityList: function() {
        this.resourcesLoaded();
        this.render();
    },

    resourcesLoaded : function() {
        this.truncatedSummary = new chorus.views.TruncatedText({model:this.model, attribute:"summary", attributeIsHtmlSafe: true, extraLine: true});
        this.activityListHeader = new chorus.views.ActivityListHeader({
              model: this.model,
              allTitle: this.model.get("name"),
              insightsTitle: this.model.get("name")
        });
    },

    postRender: function() {
        if(this.model.get("summary")) {
            this.$(".truncated_summary").removeClass("hidden");
        } else {
            this.$(".truncated_summary").addClass("hidden");
        }
    }
});