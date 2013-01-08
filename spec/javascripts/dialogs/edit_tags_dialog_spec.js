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

    describe("clicking save", function() {
        beforeEach(function() {
            spyOn(this.collection, "saveTags").andCallThrough();
            spyOn(this.dialog, "closeModal");
            this.dialog.$("button.submit").click();
        });

        it("saves tags for each model", function() {
            expect(this.collection.saveTags).toHaveBeenCalled();
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
            _.each(this.server.creates(), function(create) {create.succeed();});
            expect(this.dialog.closeModal).toHaveBeenCalled();
        });

        it("does something when the saves fail", function() {

        });
    });
});