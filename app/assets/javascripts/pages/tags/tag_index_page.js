chorus.pages.TagIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.tags") }
    ],

    setup: function() {
        var tags = new chorus.collections.TagSet();
        tags.fetchAll();

        this.mainContent = new chorus.views.MainContentView({
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title:t("tags.title_plural")}),
            contentDetails: new chorus.views.TagIndexContentDetails({ collection: tags }),
            content: new chorus.views.TagList({ collection: tags })
        });
    }
});