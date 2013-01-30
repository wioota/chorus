chorus.pages.WorkfileShowPage = chorus.pages.Base.extend({
    helpId: "workfile",

    setup: function(workspaceId, workfileId, versionId) {
        this.workspaceId = parseInt(workspaceId, 10);
        this.model = new chorus.models.Workfile({id:workfileId, workspace: {id: workspaceId}});
        if (versionId) {
            this.model.set({ versionInfo : { id: versionId } }, { silent:true });
        }

        this.dependsOn(this.model);

        this.model.fetch();

        this.workspace = this.model.workspace();
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "workfiles"});

        chorus.PageEvents.subscribe("workfileVersion:changed", this.workfileVersionChanged, this);

        this.bindings.add(this.model, "loaded", this.buildPage);
    },

    crumbs: function() {
        return [
            {label:t("breadcrumbs.home"), url:"#/"},
            {label:t("breadcrumbs.workspaces"), url:'#/workspaces'},
            {label: this.workspace.loaded ? this.workspace.displayShortName(20) : "...", url:this.workspace.showUrl()},
            {label:t("breadcrumbs.workfiles.all"), url:this.workspace.workfilesUrl()},
            {label:this.model.loaded ? this.model.get("fileName") : "..." }
        ];
    },

    buildPage: function() {
        this.model = new chorus.models.DynamicWorkfile(this.model.attributes);
        this.workspace = this.model.workspace();
        if (this.workspace.get("id") !== this.workspaceId) {
            this.dependentResourceNotFound();
            return;
        }

        chorus.PageEvents.subscribe("file:autosaved", function () {
            this.model && this.model.trigger("invalidated");
        }, this);

        var contentView = new chorus.views.WorkfileContent.buildFor(this.model);
        this.mainContent = new chorus.views.MainContentView({
            model:this.model,
            content: contentView,
            contentHeader: new chorus.views.WorkfileHeader({model:this.model}),
            contentDetails: chorus.views.WorkfileContentDetails.buildFor(this.model, contentView)
        });

        this.sidebar = chorus.views.WorkfileSidebar.buildFor({model: this.model, showVersions: true, showSchemaTabs: true});
        this.subNav = new chorus.views.SubNav({workspace:this.workspace, tab:"workfiles"});

        if (this.model.isLatestVersion() && this.model.get("hasDraft") && !this.model.isDraft) {
            var alert = new chorus.alerts.WorkfileDraft({model:this.model});
            alert.launchModal();
        }

        this.render();
    },

    workfileVersionChanged: function(versionId) {
        this.model.set({ versionInfo : { id: versionId } }, { silent:true });
        this.model.fetch();
        chorus.router.navigate(this.model.showUrl(), {trigger: false});
    }
});

