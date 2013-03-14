jasmine.sharedExamples.CheckableList = function() {
    beforeEach(function() {
        spyOn(chorus.PageEvents, 'broadcast').andCallThrough();
        this.view.render();
        this.checkboxes = this.view.$("> li input[type=checkbox]");
    });

    describe("#render", function() {
        it("renders each item in the collection", function() {
            expect(this.view.$("li").length).toBe(this.view.collection.length);
        });

        it("renders a checkbox for each item", function() {
            expect(this.checkboxes.length).toBe(this.collection.length);
        });

        it("selects the first item", function() {
            expect(this.view.$("> li").eq(0)).toHaveClass("selected");
            expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith(this.view.options.entityType + ":selected", this.collection.at(0));
        });
    });

    function expectItemChecked(expectedModels) {
        expect(chorus.PageEvents.broadcast).toHaveBeenCalled();
        var lastTwoCalls = chorus.PageEvents.broadcast.calls.slice(-2);
        var eventName = lastTwoCalls[0].args[0];

        expect(eventName).toBe("checked");
        var collection = lastTwoCalls[0].args[1];
        expect(collection).toBeA(chorus.collections[this.collection.constructorName]);

        eventName = lastTwoCalls[1].args[0];
        expect(eventName).toBe(this.view.options.entityType + ":checked");

        collection = lastTwoCalls[1].args[1];
        expect(collection).toBeA(chorus.collections[this.collection.constructorName]);
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
            expectItemChecked.call(this, [ this.collection.at(1) ]);

            this.checkboxes.eq(0).click().change();
            expectItemChecked.call(this, [ this.collection.at(1), this.collection.at(0) ]);
        });

        it("unselects items when they are re-checked", function() {
            this.checkboxes.eq(0).click().change();
            this.checkboxes.eq(0).click().change();
            expectItemChecked.call(this, [ this.collection.at(1) ]);
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
                expect(this.view.$("input[type=checkbox]:checked").length).toBe(this.collection.length);
                expect(this.view.$("input[type=checkbox]:checked").closest("li")).toHaveClass('checked');
            });

            it("broadcasts the '{{eventName}}:checked' page event with a collection of all models", function() {
                expectItemChecked.call(this, this.collection.models);
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
                    expectItemChecked.call(this, []);
                });
            });
        });
    });

    describe("when another list view broadcasts that it has updated the set of checked items", function() {
        it("refreshes the view from the set of the checked items", function() {
            this.view.render();
            this.view.selectedModels.reset(this.collection.models.slice(1));
            chorus.PageEvents.broadcast("checked", this.view.selectedModels);
            expect(this.view.$("input[type=checkbox]").eq(0)).not.toBeChecked();
            expect(this.view.$("input[type=checkbox]").eq(1)).toBeChecked();
        });
    });
};
