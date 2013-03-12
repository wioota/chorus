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
        this.collection = rspecFixtures.workfileSet();
        this.collection.reset([
            this.model1.attributes, this.model2.attributes
        ]);
        this.dialog = new chorus.dialogs.EditTags({collection: this.collection});
        spyOn(this.dialog, "closeModal");
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

    describe("clicking the close button", function(){
        beforeEach(function(){
           this.dialog.$(".cancel").click();
        });

        it("closes the dialog", function(){
            expect(this.dialog.closeModal).toHaveBeenCalled();
        });
    });

    describe("after the dialog is revealed by facebox", function() {
        it("focus moves to the tag input box", function() {
            spyOn(this.dialog.tagsInput, "focusInput");
            this.dialog.launchModal();
            expect(this.dialog.tagsInput.focusInput).toHaveBeenCalled();
            this.dialog.closeModal();
            $(document).trigger("close.facebox");
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
            this.collection = rspecFixtures.workfileSet();
            this.collection.reset([
                this.model1.attributes,
                this.model2.attributes
            ]);
            this.dialog = new chorus.dialogs.EditTags({collection: this.collection});
            spyOn(this.collection, "saveTags").andCallThrough();
            this.dialog.render();
        });

        it("displays all the relevant tags", function() {
            expect(this.dialog.$(".text-tags")).toContainText("tag1");
            expect(this.dialog.$(".text-tags")).toContainText("tag2");
            expect(this.dialog.$(".text-tags")).toContainText("tag3");
            expect(this.dialog.$(".text-button").length).toBe(3);
        });

        describe('when a tag is added', function() {
             beforeEach(function(){
                enterTag(this.dialog, "foo");
             });

            it('adds the tag to all the models', function() {
                this.collection.each(function(model) {
                    expect(model.tags().pluck('name')).toContain('foo');
                });
            });

            it('saves the tags', function() {
                expect(this.collection.saveTags).toHaveBeenCalled();
            });

            it('triggers model.change', function() {
                var savedModel = this.collection.last();
                spyOnEvent(savedModel, "change");
                this.server.lastCreate().succeed();
                expect("change").toHaveBeenTriggeredOn(savedModel);
            });

            context('when the tag is already on some of the models', function() {
               beforeEach(function(){
                   enterTag(this.dialog, 'tag2');
               });

                it('saves the tags', function() {
                    expect(this.collection.saveTags).toHaveBeenCalled();
                });

                it('adds the tag to all the models', function(){
                    this.collection.each(function(model) {
                        expect(model.tags().pluck('name')).toContain('tag2');
                    });
                });

                it('puts the new tag at the end', function(){
                    expect(this.dialog.tags().last().get('name')).toEqual('tag2');
                });
            });

            context('when the save fails', function(){
                beforeEach(function() {
                    spyOn(this.dialog, "showErrors");
                    this.server.lastCreate().failForbidden({message: "Forbidden"});
                });

                it("shows an error message", function() {
                    expect(this.dialog.showErrors).toHaveBeenCalledWith(jasmine.objectContaining({serverErrors: {message: 'Forbidden'}}));
                });
            });
        });

        describe("when a tag is removed using the x button", function() {
            beforeEach(function() {
                this.dialog.$(".text-remove:eq(0)").click();
            });

            it('removes a tag from all the models', function() {
                this.collection.each(function(model) {
                    expect(model.tags().pluck('name')).not.toContain('tag1');
                });
            });

            it('saves the tags', function(){
                expect(this.collection.saveTags).toHaveBeenCalled();
            });
        });
    });
});