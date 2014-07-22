describe("chorus.views.PageItemList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.UserSet([
            backboneFixtures.user({id: 123}),
            backboneFixtures.user({id: 456}),
            backboneFixtures.user({id: 789})
        ], {schemaId: "3"});

        this.view = new chorus.views.PageItemList({
            entityType: 'user',
            entityViewType: chorus.views.UserItem,
            collection: this.collection,
            listItemOptions: {itemOption: 123}
        });

        this.view.render();
    });

    itBehavesLike.PageItemList();
});
