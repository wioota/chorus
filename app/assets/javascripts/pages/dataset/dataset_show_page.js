chorus.pages.DatasetShowPage = chorus.pages.Base.include(
    chorus.Mixins.InstanceCredentials.page).extend({
        constructorName: "DatasetShowPage",
        helpId: "dataset",
        isInstanceBrowser: true,
        additionalClass: 'dataset_show',
        sidebarOptions: {},
        contentDetailsOptions: {},

        failurePageOptions: function() {
            return {
                title: t("invalid_route.dataset.title"),
                text: t("invalid_route.dataset.content")
            };
        },

        title: function() {
            return this.dataset.get('objectName');
        },

        setup: function() {
            this.makeModel.apply(this, arguments);
            this.dataset.fetch();
            this.mainContent = new chorus.views.LoadingSection();

            this.dependsOn(this.dataset);

            this.bindings.add(this.dataset, "loaded", this.datasetLoaded);

            this.breadcrumbRequiredResources = [this.dataset];
        },

        datasetLoaded: function() {
            this.columnSet = this.dataset.columns();
            this.fetchColumnSet();
        },

        setupMainContent: function() {
            this.customHeaderView = this.getHeaderView({
                model: this.dataset
            });

            this.mainContent = new chorus.views.MainContentList({
                modelClass: "DatabaseColumn",
                collection: this.columnSet,
                persistent: true,
                contentHeader: this.customHeaderView,
                contentDetails: new chorus.views.DatasetContentDetails(_.extend(
                    { dataset: this.dataset, collection: this.columnSet, isInstanceBrowser: this.isInstanceBrowser},
                    this.contentDetailsOptions))
            });
            this.setupSidebar();
        },

        crumbs: function() {
            return [
                {label: t("breadcrumbs.home"), url: "#/"},
                {label: t("breadcrumbs.instances"), url: '#/data_sources'},
                {label: this.dataset.instance().name(), url: this.dataset.instance().databases().showUrl() },
                {label: this.dataset.database().name(), url: this.dataset.database().showUrl() },
                {label: this.dataset.schema().name(), url: this.dataset.schema().showUrl()},
                {label: this.dataset.name()}
            ];
        },

        makeModel: function(datasetId) {
            this.model = this.dataset = new chorus.models.Dataset({
                id: datasetId
            });
        },

        fetchColumnSet: function() {
            if(!this.columnSet.loaded) {
                this.bindings.add(this.columnSet, "loaded", this.drawColumns);
                this.columnSet.fetchAll();
            }
        },

        unprocessableEntity: function() {
            this.columnSet = this.dataset.columns();
            this.setupMainContent();
            this.render();
        },

        postRender: function() {
            chorus.menu(this.$('.found_in .open_other_menu'), {
                content: this.$('.found_in .other_menu'),
                classes: "found_in_other_workspaces_menu"
            });
            chorus.menu(this.$('.published_to .open_other_menu'), {
                content: this.$('.published_to .other_menu'),
                classes: "found_in_other_workspaces_menu"
            });
        },

        setupSidebar: function() {
            this.sidebar && this.sidebar.teardown();
            this.sidebar = new chorus.views.DatasetSidebar(this.sidebarOptions);
            this.sidebar.setDataset(this.dataset);

            this.bindings.add(this.mainContent.contentDetails, "transform:sidebar", this.showSidebar);
        },

        drawColumns: function() {
            var serverErrors = this.columnSet.serverErrors;
            this.columnSet = new chorus.collections.DatabaseColumnSet(this.columnSet.models);
            this.columnSet.serverErrors = serverErrors;
            this.columnSet.loaded = true;

            this.setupMainContent();
            this.mainContent.contentDetails.options.$columnList = $(this.mainContent.content.el);

            this.render();
        },

        getHeaderView: function(options) {
            return new chorus.views.DatasetShowContentHeader(options);
        }
    }
);
