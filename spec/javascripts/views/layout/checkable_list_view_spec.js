describe("chorus.views.CheckableList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.UserSet([
            rspecFixtures.user({id: 123}),
            rspecFixtures.user({id: 456}),
            rspecFixtures.user({id: 789})
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
            this.checkedModels = new chorus.collections.Base();
            this.view = new chorus.views.CheckableList({
                entityType: 'user',
                entityViewType: chorus.views.UserItem,
                collection: this.collection,
                selectedModels: this.checkedModels
            });
            expect(this.checkedModels).toBe(this.checkedModels);
        });

        describe("event names", function() {
            it("uses the entityType as the event name by default", function() {
                var eventSpy = jasmine.createSpy("selectedSpy");
                chorus.PageEvents.subscribe("user:selected", eventSpy);
                this.view.render();
                expect(this.view.$('li:eq(1)')).toExist();
                this.view.$('li:eq(1)').click();
                expect(eventSpy).toHaveBeenCalled();
            });

            it("uses eventName if passed one", function() {
                var eventSpy = jasmine.createSpy();
                chorus.PageEvents.subscribe("alternate_event_name:selected", eventSpy);
                this.view = new chorus.views.CheckableList({
                    eventName: 'alternate_event_name',
                    entityType: 'user',
                    entityViewType: chorus.views.UserItem,
                    collection: this.collection
                });
                this.view.render();
                this.view.$('li:first').click();
                expect(eventSpy).toHaveBeenCalled();
            });
        });
    });

    describe("creating the item views", function() {
        it("passes through the list item options", function() {
            expect(this.view.liViews[0].itemView.options.itemOption).toBe(123);
        });
    });

    describe("multiple selection", function() {
        beforeEach(function() {
            chorus.PageEvents.subscribe("checked", function(collection) {
                this.checkedModels = collection.models;
            }, this);
        });

        it("clicking a checkbox adds the model to the selectedModels", function() {
            var modelToClick = this.collection.at(0);
            this.view.$("li:first input[type=checkbox]").click();
            expect(this.checkedModels).toEqual([modelToClick]);
        });

        describe('shift+click', function() {
            beforeEach(function() {
                expect(this.view.$("input[type=checkbox]:checked").length).toBe(0);
                expect(this.collection.models.length).toBeGreaterThan(2);
            });

            function shiftClick(target) {
                var event = jQuery.Event("click");
                event.shiftKey = true;
                target.trigger(event);
            }

            describe("holding shift and clicking selects the item in between", function() {
                it("clicking top to bottom", function() {
                    this.view.$("li:first input[type=checkbox]").click();
                    shiftClick(this.view.$("li:eq(2) input[type=checkbox]"));
                    expect(this.checkedModels.length).toBe(3);
                    expect(this.checkedModels).toContain(this.collection.at(0));
                    expect(this.checkedModels).toContain(this.collection.at(1));
                    expect(this.checkedModels).toContain(this.collection.at(2));
                });

                it("clicking bottom to top", function() {
                    this.view.$("li:eq(2) input[type=checkbox]").click();
                    shiftClick(this.view.$("li:first input[type=checkbox]"));
                    expect(this.checkedModels.length).toBe(3);
                    expect(this.checkedModels).toContain(this.collection.at(0));
                    expect(this.checkedModels).toContain(this.collection.at(1));
                    expect(this.checkedModels).toContain(this.collection.at(2));
                });
            });

            it("clicking without holding shift only selects the clicked item", function() {
                this.view.$("li:first input[type=checkbox]").click();
                this.view.$("li:eq(2) input[type=checkbox]").click();
                expect(this.checkedModels.length).toBe(2);
                expect(this.checkedModels).toContain(this.collection.at(0));
                expect(this.checkedModels).not.toContain(this.collection.at(1));
                expect(this.checkedModels).toContain(this.collection.at(2));
            });

            it("unchecking resets shift+click selection", function() {
                this.view.$("li:first input[type=checkbox]").click().click();
                shiftClick(this.view.$("li:last input[type=checkbox]"));
                expect(this.checkedModels.length).toBe(1);
                expect(this.checkedModels).toContain(this.collection.at(this.collection.length-1));
            });
        });
    });
});
