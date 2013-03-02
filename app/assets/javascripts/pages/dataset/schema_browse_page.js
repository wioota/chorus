chorus.pages.SchemaBrowsePage = chorus.pages.Base.include(
    chorus.Mixins.InstanceCredentials.page
).extend({
    helpId: "schema",

    setup: function(schema_id) {
        this.schema = new chorus.models.Schema({ id: schema_id });
        this.collection = this.schema.datasets();

        this.handleFetchErrorsFor(this.collection);
        this.handleFetchErrorsFor(this.schema);

        this.schema.fetch();
        this.collection.sortAsc("objectName");
        this.collection.fetch();

        this.sidebar = new chorus.views.DatasetSidebar({listMode: true});

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "dataset:checked",
            actions: [
                '<a class="associate">{{t "actions.associate_with_another_workspace"}}</a>',
                '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>'
            ],
            actionEvents: {
                'click .associate': _.bind(function() {
                    new chorus.dialogs.AssociateMultipleWithWorkspace({datasets: this.multiSelectSidebarMenu.selectedModels, activeOnly: true}).launchModal();
                }, this),
                'click .edit_tags': _.bind(function() {
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

        this.bindings.add(this.collection, 'searched', function() {
            this.mainContent.content.render();
            this.mainContent.contentFooter.render();
            this.mainContent.contentDetails.updatePagination();
        });

        this.bindings.add(this.schema, "loaded", this.schemaLoaded);
        this.breadcrumbs.requiredResources.add(this.schema);
    },

    crumbs: function() {
        return _.compact([
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.instances"), url: '#/data_sources'},
            {label: this.schema.instance().name(), url: this.schema.instance().showUrl() },
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
            contentOptions: { checkable: true },
            contentDetailsOptions: { multiSelect: true }
        });
        this.render();
    }
});
