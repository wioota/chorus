describe("chorus.views.WorkfileHeader", function() {
    beforeEach(function() {
        this.view = new chorus.views.WorkfileHeader();
        this.model = rspecFixtures.workfile.sql({
            id: this.workfileId,
            workspace: {id: this.workspaceId},
            tagNames: ['alpha', 'beta', 'gamma']
        });
        this.view.model = this.model;
        this.view.render();
    });

    describe("render", function() {
        it('shows the tag names', function() {
           expect($(this.view.el)).toContainText("alpha");
           expect($(this.view.el)).toContainText("beta");
           expect($(this.view.el)).toContainText("gamma");
        });
    });

    describe("editing tags", function() {
        var textarea;
        beforeEach(function() {
            textarea = this.view.$('textarea');
        });

        xit('shows the add tags link', function() {
            expect(this.view.$('a')).toContainTranslation('tags.add_tags');
            this.view.$('a.edit_tags').click();
            expect(this.view.$('textarea')).toExist();
        });

        function enterTag(tagName) {
            var keyup = $.Event('keyup');
            keyup.keyCode = $.ui.keyCode.ENTER;
            var enter = $.Event('enterKeyPress');
            enter.keyCode = $.ui.keyCode.ENTER;
            textarea.val(tagName);
            textarea.focus();
            textarea.trigger(enter);
            textarea.trigger(keyup);

        }

        describe("when a valid tag is entered", function() {
            beforeEach(function() {
                var tagName = _.repeat("a", 100);
                enterTag(tagName);
            });

            it("creates a new tag", function() {
                expect(this.view.$(".text-tag").length).toBe(4);
            });

            it("removes the text from the textarea", function() {
                expect(textarea.val()).toBe("");
            });
        });

        describe("when an invalid tag is entered", function() {
            var longString;
            beforeEach(function() {
                longString = _.repeat("a", 101);
                enterTag(longString);
            });

            it("does not create a new tag", function() {
                expect(this.view.$(".text-tag").length).toBe(3);
            });

            it("does not remove the text from the textarea", function() {
                expect(textarea.val()).toBe(longString);
            });

            it("shows an error message", function() {
                expect(textarea).toHaveClass("has_error");
                expect(textarea.hasQtip()).toBeTruthy();
            });

            it("entering a valid tag clears the error class", function () {
                enterTag("new-tag");
                expect(textarea).not.toHaveClass("has_error");
            });
        });

        describe("when the done button is clicked", function() {
            beforeEach(function() {
                this.view.$('input[type=hidden]').val('["alpha", "beta", "gamma"]');
                this.view.$('a.save_tags').click();
            });

            xit("closes the text box", function() {
                expect(this.view.$('textarea')).not.toExist();
            });

            it('saves the tags', function() {
                var tagSave = this.server.lastCreate();
                var requestBody = decodeURIComponent(tagSave.requestBody);
                expect(tagSave.url).toBe('/taggings');
                expect(requestBody).toContain("entity_id="+this.model.id);
                expect(requestBody).toContain("entity_type=workfile");
                expect(requestBody).toContain("tag_names[]=alpha");
                expect(requestBody).toContain("tag_names[]=beta");
                expect(requestBody).toContain("tag_names[]=gamma");
            });

            xit("displays the new tags", function() {
              expect(this.view.$('a')).toContainTranslation('tags.edit_tags');
            });
        })
    });
});
