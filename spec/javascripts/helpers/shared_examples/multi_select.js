jasmine.sharedExamples.aPageWithMultiSelect = function() {
    describe("multiple selection", function() {
        beforeEach(function() {
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
        });

        it("should have a checkbox", function() {
            expect(this.page.$(".multiselect input[type=checkbox].select_all")).toExist();
        });

        describe("when the 'select all' checkbox is checked", function() {
            it("triggers the 'selectAll' page event", function() {
                var checkbox = this.page.$(".multiselect .select_all");
                checkbox.prop("checked", true);
                checkbox.change();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectAll");
            });
        });

        describe("when the 'select all' checkbox is unchecked", function() {
            it("triggers the 'selectNone' page event", function() {
                var checkbox = this.page.$(".multiselect .select_all");
                checkbox.prop("checked", false);
                checkbox.change();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectNone");
            });
        });

        it("subscribes to 'selectNone'", function () {
            var checkbox = this.page.$(".multiselect .select_all");
            checkbox.prop("checked", true);
            chorus.PageEvents.trigger("selectNone");
            expect(checkbox.prop("checked")).toBeFalsy();
        });

        it("subscribes to 'allSelected'", function () {
            var checkbox = this.page.$(".multiselect .select_all");
            checkbox.prop("checked", false);
            chorus.PageEvents.trigger("allSelected");
            expect(checkbox.prop("checked")).toBeTruthy();
        });

        it("subscribes to 'unselectAny'", function () {
            var checkbox = this.page.$(".multiselect .select_all");
            checkbox.prop("checked", true);
            chorus.PageEvents.trigger("unselectAny");
            expect(checkbox.prop("checked")).toBeFalsy();
        });

        it("does not display the multiple selection section", function() {
            expect(this.page.$(".multiple_selection")).toHaveClass("hidden");
        });

        context("when a row has been checked", function() {
            beforeEach(function() {
                this.modalSpy = stubModals();
                chorus.PageEvents.trigger(this.page.mainContent.content.eventName + ":checked", this.page.collection.clone());
            });

            it("displays the multiple selection section", function() {
                expect(this.page.$(".multiple_selection")).not.toHaveClass("hidden");
            });

            it("has an action to edit tags", function() {
                expect(this.page.$(".multiple_selection a.edit_tags")).toExist();
            });

            itBehavesLike.aDialogLauncher(".multiple_selection a.edit_tags", chorus.dialogs.EditTags);
        });
    });
};
