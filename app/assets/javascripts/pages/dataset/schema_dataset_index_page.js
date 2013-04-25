chorus.pages.SchemaDatasetIndexPage = chorus.pages.Base.include(
    chorus.Mixins.DataSourceCredentials.page
).extend({
    constructorName: 'SchemaDatasetIndexPage',
    helpId: "schema",

    setup: function(schema_id) {
        this.schema = new chorus.models.Schema({ id: schema_id });
        this.collection = this.schema.datasets();

        this.handleFetchErrorsFor(this.collection);
        this.handleFetchErrorsFor(this.schema);

        this.listenTo(this.schema, "loaded", this.schemaLoaded);
        this.schema.fetch();
        this.collection.sortAsc("objectName");
        this.listenTo(this.collection, "loaded", this.collectionLoaded);
        this.collection.fetch();

        this.sidebar = new chorus.views.DatasetSidebar({listMode: true});

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "dataset:checked",
            actionEvents: {
                'click .associate': _.bind(function(e) {
                    e.preventDefault();
                    new chorus.dialogs.AssociateMultipleWithWorkspace({datasets: this.multiSelectSidebarMenu.selectedModels, activeOnly: true}).launchModal();
                }, this),
                'click .edit_tags': _.bind(function(e) {
                    e.preventDefault();
                    new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
                }, this)
            }
        });

        this.mainContent = new chorus.views.MainContentList({
            emptyTitleBeforeFetch: true,
            modelClass: "Dataset",
            collection: this.collection
        });

        this.subscribePageEvent("dataset:selected", function(dataset) {
            this.model = dataset;
        });

        this.listenTo(this.collection, 'searched', function() {
            this.mainContent.content.render();
            this.mainContent.contentFooter.render();
            this.mainContent.contentDetails.updatePagination();
        });

        this.breadcrumbs.requiredResources.add(this.schema);
    },

    crumbs: function() {
        return _.compact([
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.data_sources"), url: '#/data_sources'},
            {label: this.schema.dataSource().name(), url: this.schema.dataSource().showUrl() },
            this.schema.database() && {label: this.schema.database().name(), url: this.schema.database().showUrl() },
            {label: this.schema.name()}
        ]);
    },

    schemaLoaded: function() {
        var onTextChangeFunction = _.debounce(_.bind(function(e) {
            this.collection.search($(e.target).val());
            this.mainContent.contentDetails.startLoading(".count");
        }, this), 300);

        this.mainContent.teardown();

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Dataset",
            collection: this.collection,
            title: this.schema.canonicalName(),
            search: {
                placeholder: t("schema.search"),
                onTextChange: onTextChangeFunction
            },

            contentDetailsOptions: { multiSelect: true }
        });
        this.render();
    },

    collectionLoaded: function () {
        var actions = [];
        if (this.collection.first().isGreenplum()) {
            actions.push('<a class="associate" href="#">{{t "actions.associate_with_another_workspace"}}</a>');
        }
        actions.push('<a class="edit_tags" href="#">{{t "sidebar.edit_tags"}}</a>');
        this.multiSelectSidebarMenu.setActions(actions);
    }
});
