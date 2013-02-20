chorus.pages.TagIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.tags") }
    ],

    setup: function() {
        var tags = new chorus.collections.TagSet();
        tags.fetch();

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Tag",
            collection: tags,
            checkable: true
        });

        this.sidebar = new chorus.views.TagListSidebar();

        this.handleFetchErrorsFor(tags);
        this.bindings.add(tags, "loaded", this.render);
        this.bindings.add(tags, "remove", this.render);
    }
});