(function() {
    // apply arbitrary number of arguments to constructor (for routes with parameters)
    // code taken from http://stackoverflow.com/questions/1606797/use-of-apply-with-new-operator-is-this-possible/1608546#1608546
    function applyConstructor(constructor, args) {
        function chorus$Page() {
            return constructor.apply(this, args);
        }

        chorus$Page.prototype = constructor.prototype;
        return new chorus$Page();
    }

    chorus.Router = Backbone.Router.include(
        chorus.Mixins.Events
    ).extend({
        constructor: function chorus$Router() {
            Backbone.Router.apply(this, arguments);
        },

        maps:[
            // routes are evaluated in LIFO format, so adding a match-all route first will act as a fallback properly
            // (as long as `maps` is evaluated in order)
            ["*path", "InvalidRoute", "Invalid Route"],
            ["unauthorized", "Unauthorized", "Unauthorized"],
            ["forbidden", "Forbidden", "Forbidden"],
            ["invalidRoute", "InvalidRoute", "InvalidRoute"],
            ["notLicensed", "NotLicensed", "NotLicensed"],
            ["unprocessableEntity", "UnprocessableEntity"],
            ["?*query", "Dashboard", "Dashboard Home"],
            ["", "Dashboard", "Dashboard Home"],
            ["login", "Login", "Login"],
            ["search/:query", "SearchIndex", "Search"],
            ["search/:scope/:entityType/:query", "SearchIndex"],
            ["users", "UserIndex", "People"],
            ["users/:id", "UserShow", "Person"],
            ["users/:id/edit", "UserEdit", "Edit Person"],
            ["users/:id/dashboard_edit", "UserDashboardEdit", "Edit Dashboard"],
            ["users/new", "UserNew", "New Person"],
            ["workspaces", "WorkspaceIndex", "Workspaces"],
            ["workspaces/:id", "WorkspaceShow", "Workspace"],
            ["workspaces/:id/quickstart", "WorkspaceQuickstart", "Workspace Quickstart"],
            ["workspaces/:workspaceId/workfiles", "WorkfileIndex", "Workfiles"],
            ["workspaces/:workspaceId/datasets/:datasetId", "WorkspaceDatasetShow", "Workspace Dataset Show"],
            ["workspaces/:workspaceId/chorus_views/:datasetId", "ChorusViewShow", "Chorus View Show"],
            ["workspaces/:workspaceId/hadoop_datasets/:datasetId", "HdfsDatasetShow", "Hdfs Dataset Show"],
            ["workspaces/:workspaceId/workfiles/:workfileId", "WorkfileShow", "Workfile!"],
            ["workspaces/:workspaceId/workfiles/:workfileId/versions/:versionId", "WorkfileShow", "Workfile!!"],
            ["workspaces/:workspaceId/datasets", "WorkspaceDatasetIndex", "Datasets"],
            ["workspaces/:workspaceId/kaggle", "KaggleUserIndex", ""],
            ["workspaces/:workspaceId/jobs", "JobsIndex", "Jobs"],
            ["workspaces/:workspaceId/milestones", "MilestonesIndex", "Milestones"],
            ["workspaces/:workspaceId/jobs/:jobId", "JobsShow", "Job"],
            ["workspaces/:workspaceId/search/:query", "WorkspaceSearchIndex"],
            ["workspaces/:workspaceId/search/:scope/:entityType/:query", "WorkspaceSearchIndex"],
            ["workspaces/:workspaceId/tags/:name", "WorkspaceTagShow"],
            ["workspaces/:workspaceId/tags/:scope/:entityType/:name", "WorkspaceTagShow"],
            ["data_sources", "DataSourceIndex", "Datasources"],
            ["data_sources/:dataSourceId/databases", "DatabaseIndex", "Databases"],
            ["databases/:databaseId", "GpdbSchemaIndex", "Gpdb SchemaIndex"],
            ["schemas/:schemaId", "SchemaDatasetIndex", "Schema Dataset Index"],
            ["datasets/:id", "DatasetShow", "Dataset Show"],
            ["gnip_data_sources/:id", "GnipDataSourceShow", "GNIP show"],
            ["hdfs_data_sources/:dataSourceId/browse", "HdfsEntryIndex", "HdfsEntry Index"],
            ["hdfs_data_sources/:dataSourceId/browse/:id", "HdfsEntryIndex", "HdfsEntry Index"],
            ["hdfs_data_sources/:dataSourceId/browseFile/:id", "HdfsShowFile", "Hdfs Show File"],
            ["notifications", "NotificationIndex", "Notifications"],
            ["tags", "TagIndex", "Tags"],
            ["tags/:name", "TagShow", "Tag Show"],
            ["tags/:scope/:entityType/:name", "TagShow", "Tag Show"],
            ["data_sources/:id/schemas", "OracleSchemaIndex", "OracleSchema Index"],
            ["work_flows/:id", "WorkFlowShow", "Workflow"],
            ["about", "About", "About This Application"],
            ["styleguide", "StyleGuide", "Style Guide"]
        ],

        initialize:function (app) {
            var self = this;
            self.app = app;

            _.each(this.maps, function (map) {
                var pattern = map[0],
                    pageClassName = map[1],
                    //pageTitle = map[2],
                    callback = self.generateRouteCallback(pageClassName);
                self.route(pattern, pageClassName, callback);
            });

            var alternateHomePage = chorus.models.Config.instance().license().homePage();
            alternateHomePage && self.route("", alternateHomePage, self.generateRouteCallback(alternateHomePage));

            self.route("logout", "Logout", self.app.session.logout);
        },

        navigate:function (fragment, pageOptions) {
            this.app.pageOptions = pageOptions;
            fragment = fragment.match(/#?(.*)/)[1];
            var fragComparison = fragment.match(/\/?(.*)/)[1];
            if (Backbone.history.fragment === fragComparison || Backbone.history.fragment === decodeURIComponent(fragComparison)) {
                Backbone.history.loadUrl(fragment);
            } else {
                pageOptions = pageOptions || { trigger: true };
                Backbone.Router.prototype.navigate.call(this, fragment, pageOptions);
            }
        },

        reload: function() {
            this.navigate(Backbone.history.fragment);
        },

        pageRequiresLogin: function(pageName) {
            return !_.include(["Login", "StyleGuide"], pageName);
        },

        generateRouteCallback: function(className) {
            var self = this;
            return function () {
                var args = _.map(_.toArray(arguments), function(arg) {
                    return decodeURIComponent(arg);
                });
                var navFunction = function() {
                    chorus.PageEvents.off();
                    if (className === "Login" && self.app.session.loggedIn()) {
                        self.navigate("");
                    } else {
                        self.trigger("leaving");
                        var pageClass = chorus.pages[className + "Page"];
                        var page = applyConstructor(pageClass, args);
                        page.pageOptions = self.app.pageOptions;
                        delete self.app.pageOptions;
                        self.app.page = page;
                        self.app.updateCachebuster();

                        $("#page").html(page.render().el).attr("data-page", className).addClass(page.pageClass);

                        if (self.app.modal) self.app.modal.closeModal();
                    }
                    self.app.scrollToTop();
                };

                if (this.pageRequiresLogin(className) && !self.app.session.loaded) {
                    self.app.session.fetch(
                        {
                            success: navFunction,
                            error: function() { self.navigate("login"); }
                        });
                } else {
                    navFunction();
                }
            };
        }
    });
})();

