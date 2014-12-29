chorus.views.WorkspaceSummaryContent = chorus.views.Base.extend ({
    constructorName: "WorkspaceSummaryContentView",
    templateName: "workspace_summary_content",
//     additionalClass: 'taggable_header',
    useLoadingSection: true,

    subviews: {
        ".truncated_summary": "truncatedSummary",
        ".project_status": "projectStatus"
//         ,
//         ".tag_box": "tagBox"
//         ,
//         ".activity_list_header": "activityListHeader"
    },

    setup: function() {
        this.projectStatus = new chorus.views.ProjectStatus({model:this.model});
                
//         this.model.activities().fetchIfNotLoaded();
//         this.requiredResources.push(this.model);
//         *
//         this.tagBox = this.options.tagBox;
        
//         this.listenTo(this.model, "saved", this.updateHeaderAndActivityList);
    },

//     updateHeaderAndActivityList: function() {
//         this.resourcesLoaded();
//         this.render();
//     },

    additionalContext: function() {
        return {
            iconUrl: this.model && this.model.defaultIconUrl(),
            tagBox: this.tagBox
        };
    },

    resourcesLoaded: function() {
        this.truncatedSummary = new chorus.views.TruncatedText ({model:this.model, attribute:"summary", attributeIsHtmlSafe: true, extraLine: true});

        this.projectStatus = new chorus.views.ProjectStatus({model:this.model});

//         this.activityListHeader = new chorus.views.ActivityListHeader ({
//             model: this.model,
//             allTitle: this.model.get("name"),
//             insightsTitle: this.model.get("name"),
//             tagBox: new chorus.views.TagBox({
//                 model: this.model,
//                 workspaceIdForTagLink: this.model.id
//             })
//         });

    },

    postRender: function() {
        if(this.model.get("summary")) {
            this.$(".truncated_summary").removeClass("hidden");
        } else {
            this.$(".truncated_summary").addClass("hidden");
        }
    }
});