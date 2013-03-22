describe("chorus.views.CheckableList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.SchemaDatasetSet([
            rspecFixtures.dataset({id: 123}),
            rspecFixtures.dataset({id: 456})
        ], {schemaId: "3"});
        this.view = new chorus.views.CheckableList({
            entityType: 'dataset',
            entityViewType: chorus.views.DatasetItem,
            collection: this.collection,
            listItemOptions: {itemOption: 123}
        });
    });

    itBehavesLike.CheckableList();

    describe("#setup", function() {
        it("uses selectedModels if passed one", function() {
           this.selectedModels = new chorus.collections.Base();
            this.view = new chorus.views.CheckableList({
                entityType: 'dataset',
                entityViewType: chorus.views.DatasetItem,
                collection: this.collection,
                selectedModels: this.selectedModels
            });
            expect(this.view.selectedModels).toBe(this.selectedModels);
        });
    });

    describe("#render", function() {
        it("sets the list item options on the child list item views", function() {
            expect(this.view.liViews[0].options.itemOption).toBe(123);
        });
    });
});
