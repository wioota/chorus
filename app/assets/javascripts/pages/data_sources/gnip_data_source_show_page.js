chorus.pages.GnipDataSourceShowPage = chorus.pages.Base.extend({
    setup: function(id) {
        this.model = new chorus.models.GnipDataSource({id: id});
        this.model.fetch();

        this.handleFetchErrorsFor(this.model);

        this.mainContent = new chorus.views.MainContentView({
            model: this.model,
            contentHeader: new chorus.views.TaggableHeader({model: this.model})
        });

        this.sidebar = new chorus.views.DataSourceListSidebar();
        this.sidebar.setInstance(this.model);

        this.breadcrumbs.requiredResources.add(this.model);
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.instances"), url: "#/data_sources"},
            {label: this.model.name()}
        ];
    }
});
