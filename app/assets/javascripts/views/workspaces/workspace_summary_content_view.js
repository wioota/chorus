chorus.views.WorkspaceSummaryContent = chorus.views.Base.extend ({
//     constructorName: "WorkspaceSummaryContentView",
    templateName: "workspace_summary_content",
    useLoadingSection: true,
    
    subviews: {
        ".truncated_summary": "truncatedSummary",
        ".project_status": "projectStatus"

    },

    setup: function() {
        
        /* jshint ignore:start */
        console.log ("WorkspaceSummaryContentView > setup");
        /* jshint ignore:end */
       
		this.truncatedSummary = new chorus.views.TruncatedText ({model:this.model, attribute:"summary", attributeIsHtmlSafe: true, extraLine: true});
        this.projectStatus = new chorus.views.ProjectStatus({model:this.model});
        
    },

    additionalContext: function() {
        /* jshint ignore:start */
        console.log ("WorkspaceSummaryContentView > additional context");
        /* jshint ignore:end */
    
//         return {
//         };
    },

    resourcesLoaded: function() {
        this.truncatedSummary = new chorus.views.TruncatedText ({model:this.model, attribute:"summary", attributeIsHtmlSafe: true, extraLine: true});
        this.projectStatus = new chorus.views.ProjectStatus({model:this.model});

    },

    postRender: function() {
        if(this.model.get("summary")) {
            this.$(".truncated_summary").removeClass("hidden");
        } else {
            this.$(".truncated_summary").addClass("hidden");
        }
    }
});