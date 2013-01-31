chorus.pages.GnipInstanceShowPage = chorus.pages.Base.extend({
    setup: function(id) {
        this.model = new chorus.models.GnipInstance({id: id});
        this.model.fetch();

        this.dependsOn(this.model);

        this.mainContent = new chorus.views.MainContentView({
            model: this.model,
            contentHeader: new chorus.views.DisplayNameHeader({model: this.model, imageUrl: '/images/data_sources/icon_gnip_instance.png'})
        });

        this.sidebar = new chorus.views.InstanceListSidebar();
        this.sidebar.setInstance(this.model);

        this.breadcrumbRequiredResources = [this.model];
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.instances"), url: "#/data_sources"},
            {label: this.model.name()}
        ];
    }
});
