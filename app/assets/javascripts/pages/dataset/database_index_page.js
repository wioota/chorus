chorus.pages.DatabaseIndexPage = chorus.pages.Base.include(
    chorus.Mixins.InstanceCredentials.page
).extend({
    constructorName: "DatabaseIndexPage",
    helpId: "instances",

    setup: function(instanceId) {
        this.instance = new chorus.models.GpdbDataSource({id: instanceId});
        this.collection = this.instance.databases();

        this.instance.fetch();
        this.collection.fetchAll();

        this.handleFetchErrorsFor(this.instance);

        this.handleFetchErrorsFor(this.collection);

        this.mainContent = new chorus.views.MainContentList({
            emptyTitleBeforeFetch: true,
            modelClass: "Database",
            collection: this.collection,
            contentHeader: new chorus.views.TaggableHeader({model: this.instance}),
            search: {
                eventName: "database:search",
                placeholder: t("database.search_placeholder")
            }
        });

        this.sidebar = new chorus.views.DatabaseListSidebar();

        this.breadcrumbs.requiredResources.add(this.instance);
    },

    crumbs: function() {
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.instances"), url: "#/data_sources" },
            { label: this.instance.get("name") }
        ];
    }
});
