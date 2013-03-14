jasmine.sharedExamples.aPageWithMultiSelect = function() {
    describe("multiple selection", function() {
        beforeEach(function() {
            spyOn(chorus.PageEvents, "broadcast").andCallThrough();
        });

        it("should have a 'select all' and 'deselect all'", function() {
            expect(this.page.$(".multiselect span")).toContainTranslation("actions.select");
            expect(this.page.$(".multiselect a.select_all")).toContainTranslation("actions.select_all");
            expect(this.page.$(".multiselect a.select_none")).toContainTranslation("actions.select_none");
        });

        describe("when the 'select all' link is clicked", function() {
            it("broadcasts the 'selectAll' page event", function() {
                this.page.$(".multiselect a.select_all").click();
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("selectAll");
            });
        });

        describe("when the 'select none' link is clicked", function() {
            it("broadcasts the 'selectNone' page event", function() {
                this.page.$(".multiselect a.select_none").click();
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("selectNone");
            });
        });

        it("does not display the multiple selection section", function() {
            expect(this.page.$(".multiple_selection")).toHaveClass("hidden");
        });

        context("when a row has been checked", function() {
            beforeEach(function() {
                chorus.PageEvents.broadcast(this.page.mainContent.content.eventName + ":checked", this.page.collection.clone());
            });

            it("displays the multiple selection section", function() {
                expect(this.page.$(".multiple_selection")).not.toHaveClass("hidden");
            });

            it("has an action to edit tags", function() {
                expect(this.page.$(".multiple_selection a.edit_tags")).toExist();
            });

            describe("clicking the 'edit_tags' link", function() {
                beforeEach(function() {
                    this.modalSpy = stubModals();
                    this.page.$(".multiple_selection a.edit_tags").click();
                });

                it("launches the dialog for editing tags", function() {
                    expect(this.modalSpy).toHaveModal(chorus.dialogs.EditTags);
                    expect(this.modalSpy.lastModal().collection).toBe(this.page.multiSelectSidebarMenu.selectedModels);
                });
            });
        });
    });
};
