chorus.pages.HdfsEntryIndexPage = chorus.pages.Base.extend({
    helpId: "instances",

    setup:function (hdfsDataSourceId, id) {
        this.instance = new chorus.models.HdfsDataSource({ id: hdfsDataSourceId });
        this.instance.fetch();
        this.bindings.add(this.instance, "loaded", this.instanceFetched);
        this.hdfsDataSourceId = hdfsDataSourceId;

        this.hdfsEntry = new chorus.models.HdfsEntry({
            id: id,
            hdfsDataSource: {
                id: hdfsDataSourceId
            }
        });
        this.hdfsEntry.fetch();

        this.handleFetchErrorsFor(this.hdfsEntry);

        this.collection = new chorus.collections.HdfsEntrySet([], {
            hdfsDataSource: {
                id: this.hdfsDataSourceId
            }
        });

        this.mainContent = new chorus.views.MainContentList({
            contentHeader: new chorus.views.HdfsEntryHeader({dataSource: this.instance, hdfsEntry: this.hdfsEntry}),
            modelClass: "HdfsEntry",
            collection: this.collection,
            useCustomList: true,
            contentDetailsOptions: {multiSelect: true}
        });

        this.sidebar = new chorus.views.HdfsEntrySidebar({
            hdfsDataSourceId: this.hdfsDataSourceId
        });

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "hdfs_entry:checked",
            actions: [
                '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>'
            ],
            actionEvents: {
                'click .edit_tags': _.bind(function() {
                    new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
                }, this)
            }
        });

        this.subscribePageEvent("hdfs_entry:selected", this.entrySelected);

        this.bindings.add(this.hdfsEntry, "loaded", this.entryFetched);
    },

    crumbs: function() {
        var path = this.hdfsEntry.get("path") || "";
        var pathLength = _.compact(path.split("/")).length + 1;
        var modelCrumb = this.instance.get("name") + (pathLength > 0 ? " (" + pathLength + ")" : "");
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.instances"), url: "#/data_sources" },
            { label: this.instance.loaded ? modelCrumb : "..." }
        ];
    },

    instanceFetched: function() {
        if(this.hdfsEntry.loaded) {
            this.render();
        }
    },

    entryFetched: function() {
        this.collection.reset(this.hdfsEntry.get("entries"));

        this.entrySelected(this.collection.at(0));

        this.collection.loaded = true;

        if(this.instance.loaded) {
            this.render();
        }
    },

    postRender: function() {
        if (this.path === "/") {
            return;
        }

        var $content = $("<ul class='hdfs_link_menu'/>");

        var $li = $("<li/>");

        var pathSegments = this.hdfsEntry.pathSegments();
        var maxLength = 20;

        _.each(pathSegments, function(hdfsEntry) {
            var link = $("<a></a>").attr('href', hdfsEntry.showUrl()).text(_.truncate(hdfsEntry.get('name'), maxLength));
            $content.append($("<li></li>").append(link));
        });

        chorus.menu(this.$(".breadcrumb").eq(2), {
            content: $content,

            qtipArgs: {
                show: { event: "mouseenter"},
                hide: { event: "mouseleave", delay: 500, fixed: true }
            }
        });
    },

    ellipsizePath: function() {
        var dir = this.hdfsEntry.get("path");
        if (this.hdfsEntry.name() === "/") {
          dir = "";
        } else if (!dir.match(/\/$/)) {
            dir += '/';
        }
        var path = dir + this.hdfsEntry.name();
        var folders = path.split('/');
        if (folders.length > 3) {
            return "/" + folders[1] + "/.../" + folders[folders.length-1];
        } else {
            return path;
        }
    },

    entrySelected : function(model) {
        this.model = model;
    }
});
