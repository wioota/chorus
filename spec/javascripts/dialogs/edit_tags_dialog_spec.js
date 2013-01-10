describe("chorus.dialogs.EditTags", function() {
    beforeEach(function() {
        this.model1 = rspecFixtures.workfile.sql({tags: [
            {name: "tag1"},
            {name: "tag2"}
        ]});
        this.model2 = rspecFixtures.workfile.sql({tags: [
            {name: "tag1"},
            {name: "tag3"}
        ]});
        this.collection = rspecFixtures.workfileSet([
            this.model1.attributes, this.model2.attributes]);
        this.dialog = new chorus.dialogs.EditTags({collection: this.collection});
        this.dialog.render();
    });

    it("has the right title", function() {
        expect(this.dialog.title).toMatchTranslation("edit_tags.title");
    });

    it("displays all the relevant tags", function() {
        expect(this.dialog.$(".text-tags")).toContainText("tag1");
        expect(this.dialog.$(".text-tags")).toContainText("tag2");
        expect(this.dialog.$(".text-tags")).toContainText("tag3");
    });

    describe("after the dialog is revealed by facebox", function() {
        // TODO #42306281: get this working on ci
        xit("focus moves to the tag input box", function() {
            $('#jasmine_content').append(this.dialog.el);
            this.dialog.launchModal();
            expect(this.dialog.$('.tag_editor').is(":focus")).toBeTruthy();
            this.dialog.closeModal();
            $(document).trigger("close.facebox");
        });
    });

    describe("clicking save", function() {
        beforeEach(function() {
            spyOn(this.collection, "saveTags").andCallThrough();
            spyOn(this.dialog, "closeModal");
            enterTag(this.dialog, "new_tag");
            this.dialog.$("button.submit").click();
        });

        it("saves tags for each model", function() {
            expect(this.collection.saveTags).toHaveBeenCalled();
        });

        it("includes the new tag", function() {
            this.collection.each(function(model) {
                expect(model.tags().pluck("name")).toContain("new_tag");
            });
        });

        it("starts the loading spinner", function() {
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
        });

        it("doesn't do anything except trigger model.change when one of the saves succeeds", function() {
            var savedModel = this.collection.last();
            spyOnEvent(savedModel, "change");
            this.server.lastCreateFor(savedModel.tags()).succeed();
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
            expect(this.dialog.closeModal).not.toHaveBeenCalled();
            expect("change").toHaveBeenTriggeredOn(savedModel);

        });

        it("closes the dialog and triggers 'change' on the collection models when all of the saves succeed", function() {
            spyOnEvent(this.collection.at(0), "change");
            _.each(this.server.creates(), function(create) {
                create.succeed();
            });
            expect(this.dialog.closeModal).toHaveBeenCalled();
        });

        context("when the save fails", function() {
            beforeEach(function() {
                var savedModel = this.collection.last();
                spyOn(this.dialog, "showErrors");
                this.server.lastCreateFor(savedModel.tags()).failForbidden({message: "Forbidden"});
            });

            it("shows an error message", function() {
                expect(this.dialog.showErrors).toHaveBeenCalledWith(this.collection.last().tags());
            });

            it("stops the spinner", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
            });
        });

    });

    describe("clicking save before enter is pressed on the currently edited tag", function() {
        context("when the last tag is valid", function() {
            beforeEach(function() {
                this.dialog.$("input").val("unentered_tag");
                this.dialog.$("button.submit").click();
            });

            it("includes that last tag", function() {
                this.collection.each(function(model) {
                    expect(model.tags().pluck("name")).toContain("unentered_tag");
                });
            });
        });

        context("when the last tag is invalid (because it already exists)", function() {
            beforeEach(function() {
                this.tooLongTag = _.repeat("a", 101);
                this.dialog.$("input").val(this.tooLongTag);
                this.dialog.$("button.submit").click();
            });

            it("does not include that last tag", function() {
                this.collection.each(function(model) {
                    expect(model.tags().pluck("name")).not.toContain(this.tooLongTag);
                });
            });

            it("should not do post", function() {
                expect(this.server.lastCreate()).toBeUndefined();
            });
        });
    });

    describe("cancel/x", function() {
        beforeEach(function() {
            enterTag(this.dialog, "bad_tag");
            this.dialog.$("a.close").click();
        });

        it("resets the tags on the models to their original values", function() {
            expect(this.collection.at(0).tags().pluck("name")).toEqual(["tag1", "tag2"]);
            expect(this.collection.at(1).tags().pluck("name")).toEqual(["tag1", "tag3"]);
        });
    });

    describe("editing tags", function() {
        beforeEach(function() {
            this.model1 = rspecFixtures.workfile.sql({
                tags: [
                    {name: "tag1"},
                    {name: "tag2"}
                ]
            });
            this.model2 = rspecFixtures.workfile.sql({
                tags: [
                    {name: "tag1"},
                    {name: "tag3"}
                ]
            });
            this.collection = rspecFixtures.workfileSet([
                this.model1.attributes,
                this.model2.attributes]);
            this.dialog = new chorus.dialogs.EditTags({collection: this.collection});
            this.dialog.render();
        });

        it("displays all the relevant tags", function() {
            expect(this.dialog.$(".text-tags")).toContainText("tag1");
            expect(this.dialog.$(".text-tags")).toContainText("tag2");
            expect(this.dialog.$(".text-tags")).toContainText("tag3");
            expect(this.dialog.$(".text-button").length).toBe(3);
        });

        it("adds a tag to all models when you add a tag", function() {
            enterTag(this.dialog, "foo");
            expect(this.collection.at(0).editableTags.pluck("name")).toEqual(["tag1", "tag2", "foo"]);
            expect(this.collection.at(1).editableTags.pluck("name")).toEqual(["tag1", "tag3", "foo"]);
        });

        it("removes a tag from all models when you remove a tag", function() {
            this.dialog.$(".text-remove:eq(0)").click();
            expect(this.collection.at(0).editableTags.pluck("name")).toEqual(["tag2"]);
            expect(this.collection.at(1).editableTags.pluck("name")).toEqual(["tag3"]);
        });
    });
});