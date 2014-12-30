chorus.views.WorkspaceShow = chorus.views.Base.extend({
    constructorName: "WorkspaceShowView",
    templateName: "workspace_show",
    useLoadingSection: true,

    subviews: {
        ".workspace_summary_content": "workspaceSummaryContent",
        ".activity_list_header": "activityListHeader",
        ".activity_list": "activityList"
    },

    setup:function () {
    
    	/* jshint ignore:start */
        console.log ("WorkspaceShowView > setup");
        /* jshint ignore:end */
        
//         this.projectStatus = new chorus.views.ProjectStatus({model:this.model});
        
        this.workspaceSummaryContent = new chorus.views.WorkspaceSummaryContent({
        	 model: this.model,
        });
        
        this.collection = this.model.activities({insights: chorus.pageParams().filter === 'insights'});
        this.collection.fetch();
        this.requiredResources.add(this.collection);

        this.activityList = new chorus.views.ActivityList({
            collection: this.collection,
            additionalClass: "workspace_detail",
            displayStyle: "without_workspace"
        });
    },

    resourcesLoaded : function() {

        this.activityListHeader = new chorus.views.ActivityListHeader({
            model: this.model,
            allTitle: this.model.get("name"),
            insightsTitle: this.model.get("name"),
        });

    }
    
});
