chorus.pages.OracleSchemaIndexPage = chorus.pages.Base.extend({
    setup: function(oracleDataSourceId){
        this.dataSource = new chorus.models.OracleDataSource({id: oracleDataSourceId});
        this.collection = this.dataSource.schemas();
        this.dataSource.fetch();
        this.collection.fetch();
        this.requiredResources.add(this.dataSource);

        this.mainContent = new chorus.views.MainContentList({
            title: _.bind(this.dataSource.name, this.dataSource),
            modelClass: "Schema",
            collection: this.collection,
            search: {
                selector: ".name",
                placeholder: t("schema.search_placeholder"),
                eventName: "schema:search"
            }
        });

        this.sidebar = new chorus.views.SchemaListSidebar();
        this.breadcrumbs.requiredResources.add(this.dataSource);
    },

    crumbs: function() {
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.instances"), url: "#/data_sources" },
            { label: this.dataSource.name() }
        ];
    }
});