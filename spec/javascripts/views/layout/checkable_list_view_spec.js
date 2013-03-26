describe("chorus.views.CheckableList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.UserSet([
            rspecFixtures.user({id: 123}),
            rspecFixtures.user({id: 456})
        ], {schemaId: "3"});

        this.view = new chorus.views.CheckableList({
            entityType: 'user',
            entityViewType: chorus.views.UserItem,
            collection: this.collection,
            listItemOptions: {itemOption: 123}
        });
    });

    itBehavesLike.CheckableList();

    describe("#setup", function() {
        it("uses selectedModels if passed one", function() {
           this.selectedModels = new chorus.collections.Base();
            this.view = new chorus.views.CheckableList({
                entityType: 'user',
                entityViewType: chorus.views.UserItem,
                collection: this.collection,
                selectedModels: this.selectedModels
            });
            expect(this.view.selectedModels).toBe(this.selectedModels);
        });
    });

    describe("creating the item views", function() {
        it("passes through the list item options", function() {
            expect(this.view.liViews[0].itemView.options.itemOption).toBe(123);
        });
    });
});
