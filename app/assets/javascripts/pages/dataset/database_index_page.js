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

        this.dependsOn(this.instance);
        this.bindings.add(this.instance, "loaded", this.instanceLoaded);

        this.dependsOn(this.collection);

        this.mainContent = new chorus.views.MainContentList({
            emptyTitleBeforeFetch: true,
            modelClass: "Database",
            collection: this.collection
        });

        this.sidebar = new chorus.views.DatabaseListSidebar();
    },

    instanceLoaded: function() {
        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Database",
            collection: this.collection,
            title: this.instance.get("name"),
            imageUrl: this.instance.providerIconUrl(),
            search: {
                eventName: "database:search",
                placeholder: t("database.search_placeholder")
            }
        });

        this.render();
    },

    crumbs: function() {
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.instances"), url: "#/data_sources" },
            { label: this.instance.get("name") }
        ];
    }
});
