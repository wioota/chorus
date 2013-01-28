chorus.pages.TagShowPage = chorus.pages.Base.extend({

    crumbs: function() {
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.tags"), url: "#/tags" },
            { label: this.model.name() }
        ];
    },

    setup: function(name) {
        this.model = new chorus.models.Tag({name: name});
        this.mainContent = new chorus.views.MainContentView({
            contentHeader: new chorus.views.ListHeaderView({
                title: t("tag.show.title", {
                    name: this.model.name()
                })
            })
        });
    }
});
