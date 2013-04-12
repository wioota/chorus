chorus.views.WorkfileSidebar = chorus.views.Sidebar.extend({
    constructorName: "WorkfileSidebar",
    templateName:"workfile_sidebar",
    useLoadingSection:true,

    options: {
        showEditingLinks: true,
        showDownloadLink: true,
        showUpdatedTime: true
    },
    subviews:{
        '.tab_control': 'tabs'
    },

    events: {
        "click a.version_list": 'displayVersionList',
        "click .edit_tags": 'startEditingTags'
    },

    setup:function () {
        this.tabs = new chorus.views.TabControl();

        if(this.model) {
            this.setWorkfile(this.model);
        }
    },

    setWorkfile:function (workfile) {
        this.resource = this.model = workfile;
        if (this.model) {
            this.collection = this.model.activities();
            this.listenTo(this.collection, "reset", this.render);
            this.listenTo(this.collection, "changed", this.render);
            this.listenTo(this.model, "changed", this.render);
            this.collection.fetch();

            if(this.options.showVersions) {
                this.allVersions = this.model.allVersions();
                this.versionList = new chorus.views.WorkfileVersionList({collection:this.allVersions});
                this.listenTo(this.model, "invalidated", _.bind(this.allVersions.fetch, this.allVersions));
                this.listenTo(this.allVersions, "changed", this.render);

                this.allVersions.fetch();
                this.subscribePageEvent("workfile_version:deleted", this.versionDestroyed);
            }

            this.tabs.activity = new chorus.views.ActivityList({
                collection:this.collection,
                additionalClass:"sidebar",
                displayStyle:['without_object', 'without_workspace']
            });
            this.tabs.bind("selected", _.bind(this.recalculateScrolling, this));
            this.onceLoaded(this.model, this.modelLoaded);

        } else {
            delete this.collection;
            delete this.allVersions;
            delete this.tabs.activity;
        }

        this.render();
    },

    modelLoaded:function () {
        if (this.options.showSchemaTabs && this.model.isSql() && this.model.workspace().isActive()) {
            this.tabs.tabNames = ["data","database_function_list","activity"];
            var schema = this.model.executionSchema();
            this.tabs.database_function_list = new chorus.views.FunctionTab({ schema: schema });
            this.tabs.data = this.tabs.data || new chorus.views.DataTab({ schema: schema });
        } else {
            this.tabs.tabNames = ["activity"];
        }

        this.tabs.activity = new chorus.views.ActivityList({
            collection: this.collection,
            additionalClass: "sidebar",
            displayStyle: ['without_object', 'without_workspace']
        });
        this.tabs.bind("selected", _.bind(this.recalculateScrolling, this));
    },

    additionalContext:function () {
        var workspaceActive = this.model && this.model.workspace().isActive();
        var ctx = {
            showAddNoteLink: workspaceActive && this.options.showEditingLinks,
            showCopyLink: true,
            showDownloadLink: this.options.showDownloadLink,
            showDeleteLink: workspaceActive && this.options.showEditingLinks && this.model.workspace().canUpdate(),
            showUpdatedTime: this.options.showUpdatedTime,
            showVersions: this.options.showVersions
        };

        if (this.model) {
            ctx.downloadUrl = this.model.downloadUrl();
            if(this.model.isTableau()) {
                ctx.showCopyLink = false;
                ctx.showDownloadLink = false;
                ctx.showDeleteLink = false;
                ctx.showUpdatedTime = false;
                ctx.showVersions = false;
            }
            _.extend(ctx, this.modifierContext());
        }
        return ctx;
    },

    modifierContext: function() {
        var modifier = this.model.modifier();
        return {
            updatedBy: modifier.displayShortName(),
            modifierUrl: modifier.showUrl()
        };
    },

    postRender:function () {
        if(this.options.showVersions) {
            var versionList = this.versionList.render();
            chorus.menu(this.$('a.version_list'), {
                content:$(versionList.el)
            });
            this.versionList.delegateEvents(this.versionList.events);
        }
        this._super('postRender');
    },

    versionDestroyed: function(versionNumber) {
        if(versionNumber === this.model.get("versionInfo").versionNum) {
            chorus.router.navigate(this.model.baseShowUrl());
        } else {
            this.allVersions.fetch();
        }
    },

    displayVersionList:function (e) {
        e.preventDefault();
    },

    startEditingTags: function(e) {
        e.preventDefault();
        new chorus.dialogs.EditTags({collection: new chorus.collections.Base([this.model])}).launchModal();
    }

},
{
    typeMap: {
        alpine: 'AlpineWorkfileSidebar'
    },

    buildFor: function(options) {
        var workfileType = options.model.get("entitySubtype");

        if (!chorus.views[this.typeMap[workfileType]]) {
            return new chorus.views.WorkfileSidebar(options);
        }

        return new chorus.views[this.typeMap[workfileType]](options);
    }
});
