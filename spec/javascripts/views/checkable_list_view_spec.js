describe("chorus.views.CheckableList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.DatasetSet([
            rspecFixtures.dataset(),
            rspecFixtures.dataset()
        ], {schemaId: "3"});
        this.view = new chorus.views.CheckableList({
            entityType: 'dataset',
            entityViewType: chorus.views.Dataset,
            collection: this.collection
        });

        spyOn(chorus.PageEvents, 'broadcast').andCallThrough();
    });

    describe("#setup", function() {
        it("uses selectedModels if passed one", function() {
           this.selectedModels = new chorus.collections.Base();
            this.view = new chorus.views.CheckableList({
                entityType: 'dataset',
                entityViewType: chorus.views.Dataset,
                collection: this.collection,
                selectedModels: this.selectedModels
            });
            expect(this.view.selectedModels).toBe(this.selectedModels);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
            this.checkboxes = this.view.$("> li input[type=checkbox]");
        });

        it("renders each item in the collection", function() {
            expect(this.view.$("li.dataset").length).toBe(2);
        });

        it("renders a checkbox for each item", function() {
            expect(this.checkboxes.length).toBe(2);
        });

        it("selects the first item", function() {
            expect(this.view.$("> li").eq(0)).toHaveClass("selected");
            expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("dataset:selected", this.collection.at(0));
        });
    });

    function expectItemChecked(expectedModels) {
        expect(chorus.PageEvents.broadcast).toHaveBeenCalled();
        var lastTwoCalls = chorus.PageEvents.broadcast.calls.slice(-2);
        var eventName = lastTwoCalls[0].args[0];

        expect(eventName).toBe("checked");
        var collection = lastTwoCalls[0].args[1];
        expect(collection).toBeA(chorus.collections.DatasetSet);

        eventName = lastTwoCalls[1].args[0];
        expect(eventName).toBe("dataset:checked");

        collection = lastTwoCalls[1].args[1];
        expect(collection).toBeA(chorus.collections.DatasetSet);
        expect(collection.pluck("id")).toEqual(_.pluck(expectedModels, "id"));
    }

    describe("checking an item", function() {
        beforeEach(function() {
            this.view.render();
            this.checkboxes = this.view.$("> li input[type=checkbox]");
            this.checkboxes.eq(1).click().change();
        });

        it("does not 'select' the item", function() {
            expect(this.view.$("li").eq(1)).not.toBe(".selected");
        });

        it("add class checked", function() {
            expect(this.view.$("li").eq(1)).toHaveClass('checked');
        });

        it("broadcasts the '{{eventName}}:checked' event with the collection of currently-checked items", function() {
            expectItemChecked([ this.collection.at(1) ]);

            this.checkboxes.eq(0).click().change();
            expectItemChecked([ this.collection.at(1), this.collection.at(0) ]);
        });

        it("unselects items when they are re-checked", function() {
            this.checkboxes.eq(0).click().change();
            this.checkboxes.eq(0).click().change();
            expectItemChecked([ this.collection.at(1) ]);
        });

        it("retains checked items after collection fetches", function() {
            this.view.collection.fetch();
            this.server.completeFetchFor(this.view.collection, this.view.collection.models);
            expect(this.view.$("input[type=checkbox]").filter(":checked").length).toBe(1);
            expect(this.view.$("input[type=checkbox]").eq(1)).toBe(":checked");
        });
    });

    describe("select all and select none", function() {
        context("when the selectAll page event is received", function() {
            beforeEach(function() {
                this.view.render();
                chorus.PageEvents.broadcast("selectAll");
            });

            it("checks all of the items", function() {
                expect(this.view.$("input[type=checkbox]:checked").length).toBe(2);
                expect(this.view.$("input[type=checkbox]:checked").closest("li")).toHaveClass('checked');
            });

            it("broadcasts the '{{eventName}}:checked' page event with a collection of all models", function() {
                expectItemChecked(this.collection.models);
            });

            context("when the selectNone page event is received", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("selectNone");
                });

                it("un-checks all of the items", function() {
                    expect(this.view.$("input[type=checkbox]:checked").length).toBe(0);
                    expect(this.view.$("li.checked").length).toBe(0);

                });

                it("broadcasts the '{{eventName}}:checked' page event with an empty collection", function() {
                    expectItemChecked([]);
                });
            });
        });

    });
});