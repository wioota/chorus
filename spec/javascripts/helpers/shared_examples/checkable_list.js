jasmine.sharedExamples.CheckableList = function() {
    beforeEach(function() {
        this.eventSpy = spyOn(chorus.PageEvents, "broadcast").andCallThrough();
        this.view.render();
        this.checkboxes = this.view.$("> li input[type=checkbox]");
    });

    describe("#render", function() {
        it("is a ul with class list", function() {
            expect($(this.view.el).is("ul.list")).toBe(true);
        });

        it("renders each item in the collection", function() {
            expect(this.view.$("li").length).toBe(this.view.collection.length);
        });

        it("selects the first item", function() {
            expect(this.view.$("> li").eq(0)).toHaveClass("selected");
            expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith(this.view.options.entityType + ":selected", this.collection.at(0));
            expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("selected", this.collection.at(0));
        });
    });

    describe('when an item is changed', function(){
        it("does not re-render the entire list", function() {
            spyOn(this.view, 'preRender');
            this.collection.at(0).trigger('change');
            expect(this.view.preRender).not.toHaveBeenCalled();
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
        // workaround since browser and jquery trigger native handler and custom handler in different orders
        // see http://bugs.jquery.com/ticket/3827
        // probably fixed by jquery 1.9
        function safeClick(target) {
            var checked = $(target).prop('checked');
            $(target).click();
            $(target).prop('checked', !checked);
        }

        beforeEach(function() {
            this.view.render();
            $('#jasmine_content').append(this.view.el);
            this.checkboxes = this.view.$("> li input[type=checkbox]");
            safeClick(this.checkboxes.eq(1));
        });

        it("checks the checkbox", function() {
            expect(this.view.$("li input[type=checkbox]").eq(1)).toBeChecked();
        });

        it("does not 'select' the item", function() {
            expect(this.view.$("li").eq(1)).not.toBe(".selected");
        });

        it("adds class checked", function() {
            expect(this.view.$("li").eq(1)).toHaveClass('checked');
        });

        it("broadcasts the '{{eventName}}:checked' event with the collection of currently-checked items", function() {
            expectItemChecked.call(this, [ this.collection.at(1) ]);
            this.checkboxes.eq(0).click();
            expectItemChecked.call(this, [ this.collection.at(1), this.collection.at(0) ]);
        });

        it("unselects items when they are re-checked", function() {
            this.checkboxes.eq(0).click();
            this.checkboxes.eq(0).click();
            expectItemChecked.call(this, [ this.collection.at(1) ]);
        });

        it("retains checked items after collection fetches", function() {
            this.view.collection.fetch();
            this.server.completeFetchFor(this.view.collection, this.view.collection.models);
            expect(this.view.$("input[type=checkbox]").filter(":checked").length).toBe(1);
            expect(this.view.$("input[type=checkbox]").eq(1)).toBe(":checked");
        });

        it('is persisted when the item is re-rendered', function(){
            expect(this.view.$("input[type=checkbox]").eq(1)).toBeChecked();
            expect(this.view.$("li").eq(1)).toHaveClass('checked');
            this.view.collection.at(1).trigger('change');
            expect(this.view.$("input[type=checkbox]").eq(1)).toBeChecked();
            expect(this.view.$("li").eq(1)).toHaveClass('checked');
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

        it("doesn't check models with the same id but different entity types", function() {
            this.view.render();
            var decoyModel = this.view.collection.at(0).clone();
            decoyModel.set({entityType: "notReal"});
            this.view.selectedModels.reset(this.collection.models.slice(1));
            this.view.selectedModels.add([decoyModel]);
            chorus.PageEvents.broadcast("checked", this.view.selectedModels);
            expect(this.view.$("input[type=checkbox]").eq(0)).not.toBeChecked();
            expect(this.view.$("input[type=checkbox]").eq(1)).toBeChecked();
        });
    });

    describe("clicking on the same entry again", function() {
        beforeEach(function() {
            this.eventSpy.reset();
            this.view.$("> li").eq(0).click();
        });

        it("doesn't fire the selected event again", function() {
            expect(this.eventSpy).not.toHaveBeenCalled();
        });
    });

    describe("clicking another entry", function() {
        beforeEach(function() {
            this.view.$("> li").eq(1).click();
        });

        it("selects only that entry", function() {
            expect(this.view.$("> li").eq(0)).not.toHaveClass("selected");
            expect(this.view.$("> li").eq(1)).toHaveClass("selected");
        });

        it("should call itemSelected with the selected model and broadcast a general selected event", function() {
            expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith(this.view.options.entityType + ":selected", this.collection.at(1));
            expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("selected", this.collection.at(1));
        });

        describe("rerendering", function() {
            beforeEach(function() {
                this.view.render();
            });

            it("keeps the entry selected", function() {
                expect(this.view.$("> li").eq(1)).toHaveClass("selected");
            });
        });

        describe("loading the next page of results", function() {
            beforeEach(function() {
                this.collection.fetchPage(2);
                this.server.completeFetchFor(this.collection, this.collection.models, {page: 2});
            });

            it("selects the first item on that page", function() {
                expect(this.view.$("> li").eq(0)).toHaveClass("selected");
            });
        });

        describe("selecting an item that does not exist", function() {
            beforeEach(function() {
                this.view.$("li").addClass("hidden");
                this.view.selectItem(this.view.$("li:not(:hidden)").eq(0));
            });

            it("broadcasts an item deselected event", function() {
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith(this.view.options.entityType + ":deselected");
            });
        });

        describe("when eventName:search is triggered", function() {
            beforeEach(function() {
                this.collection.loaded = true;
                $("#jasmine_content").append(this.view.el);
                this.view.render();

                this.view.$("li").eq(0).removeClass("selected").addClass("hidden");
                chorus.PageEvents.broadcast(this.view.options.entityType + ":search");
            });

            it("selects the first visible item", function() {
                expect(this.view.$("li").eq(0)).not.toHaveClass("selected");
                expect(this.view.$("li").eq(1)).toHaveClass("selected");
            });
        });
    });
};