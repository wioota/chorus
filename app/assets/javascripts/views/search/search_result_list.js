chorus.views.SearchResultList = chorus.views.Base.extend({
    constructorName: "SearchResultList",
    templateName: "search_result_list",

    events: {
        "click a.show_all": "showAll"
    },

    subviews: {
        ".list": "list"
    },

    setup: function() {
        this.search = this.options.search;
        this.entityType = this.options.entityType;
        this.list = this.buildList();
    },

    buildList: function() {
        return new chorus.views.CheckableList({
            collection: this.collection,
            entityViewType: chorus.views["Search" + _.classify(this.options.entityType)],
            listItemOptions: {search: this.options.search}
        });
    },

    additionalContext: function() {
        return {
            entityType: this.entityType,
            shown: this.collection.models.length,
            total: this.collection.pagination.records,
            hideHeaders: this.search && this.search.isPaginated() && !this.search.workspace(),
            moreResults: (this.collection.models.length < this.collection.pagination.records),
            title: this.title()
        };
    },

    title: function() {
         return t("search.type." + this.entityType);
    },

    showAll: function(e) {
        e.preventDefault();
        this.search.set({entityType: $(e.currentTarget).data("type")});
        delete this.search.attributes.workspaceId;
        chorus.router.navigate(this.search.showUrl());
    }
});
