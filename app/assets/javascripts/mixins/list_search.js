chorus.Mixins.ListSearch = {
    debouncedCollectionSearch: function() {
        return  _.debounce(_.bind(function(e) {
            this.mainContent.contentDetails.startLoading(".count");
            this.collection.search($(e.target).val());
        }, this), 300);
    },

    setupOnSearched: function() {
        this.listenTo(this.collection, 'searched', function() {
            this.mainContent.content.render();
            this.mainContent.contentFooter.render();
            this.mainContent.contentDetails.updatePagination();
        });
    }
};
