describe("chorus.views.TagBox", function() {
    var view, model;

    beforeEach(function() {
        view = new chorus.views.TagBox();
        model = rspecFixtures.workfile.sql({
            tagNames: []
        });
        view.model = model;
    });

    describe("#render", function() {
        beforeEach(function() {
            view.render();
        });

        context("when there are no tags", function() {
            it('shows the add tags link, textarea is hidden', function() {
                expect(view.$('a')).toContainTranslation('tags.add_tags');
                expect(view.$('.text-core')).toHaveClass("hidden");
                expect(view.$(".save_tags")).toHaveClass("hidden");
                expect(view.$("textarea")).toBeDisabled();
            });
        });

        context("when there are already tags", function() {
            beforeEach(function() {
                model = rspecFixtures.workfile.sql({
                    tagNames: ["alpha"]
                });
                view.model = model;
                view.render();
            });

            it("should show the tags without border", function() {
                expect(view.$('.text-core')).not.toHaveClass("hidden");
                expect(view.$('.text-tag').eq(0).text()).toBe("alpha");
                expect(view.$('textarea')).toHaveClass("borderless");
                expect(view.$("textarea")).toBeDisabled();
            });

            it("should show tags without the x's", function() {
                expect(view.$(".text-button:eq(0)")).toHaveClass("disabled");
            });

            it("only shows the edit tags link", function() {
                expect(view.$(".save_tags")).toHaveClass("hidden");
                expect(view.$(".edit_tags")).not.toHaveClass("hidden");
                expect(view.$('a')).toContainTranslation('tags.edit_tags');
            });
        });
    });

    describe("when there are no tags", function() {
        beforeEach(function() {
            view.render();
        });
        context("clicking on add tags", function() {
            it('shows the textarea' , function() {
                expect(view.$('.save_tags')).toHaveClass("hidden");
                expect(view.$('.edit_tags')).not.toHaveClass("hidden");
                view.$('a.edit_tags').click();
                expect(view.$('.text-core')).not.toHaveClass("hidden");
                expect(view.$('.save_tags')).not.toHaveClass("hidden");
                expect(view.$('.edit_tags')).toHaveClass("hidden");
                expect(view.$("textarea")).not.toBeDisabled();
                expect(view.$('textarea')).not.toHaveClass("borderless");
            });
        });
    });

    describe("When there are some existing tags", function() {

        beforeEach(function() {
            view.model.set('tagNames', ['alpha', 'beta', 'gamma']);
            view.render();
        });

        it('shows the tag names', function() {
            expect(view.$el).toContainText("alpha");
            expect(view.$el).toContainText("beta");
            expect(view.$el).toContainText("gamma");
        });

        describe("When edit is clicked", function() {
            var textarea;

            beforeEach(function() {
                textarea = view.$('textarea');
                view.$('a.edit_tags').click();
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

            it('shows the x character on the tags', function() {
                expect(view.$(".text-button").eq(0)).not.toHaveClass("disabled");
            });

            describe("when a valid tag is entered", function() {
                beforeEach(function() {
                    var tagName = _.repeat("a", 100);
                    enterTag(tagName);
                });

                it("creates a new tag", function() {
                    expect(view.$(".text-tag").length).toBe(4);
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
                    expect(view.$(".text-tag").length).toBe(3);
                    expect(view.model.get("tagNames").length).toBe(3);
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


            describe("click done", function() {
                beforeEach(function() {
                    view.$('input[type=hidden]').val('["alpha", "beta", "delta"]');
                    view.$('a.save_tags').click();
                });

                it("closes the text box", function() {
                    expect(view.$('.save_tags')).toHaveClass("hidden");
                    expect(view.$('.edit_tags')).not.toHaveClass("hidden");
                    expect(view.$("textarea")).toBeDisabled();
                    expect(view.$("textarea")).toHaveClass("borderless");
                });

                it("sets the updated tags on the currect backbone model", function() {
                    expect(view.model.get("tagNames")).toEqual(["alpha", "beta", "delta"]);
                });

                it('saves the tags', function() {
                    var tagSave = this.server.lastCreate();
                    var requestBody = decodeURIComponent(tagSave.requestBody);
                    expect(tagSave.url).toBe('/taggings');
                    expect(requestBody).toContain("entity_id="+model.id);
                    expect(requestBody).toContain("entity_type=workfile");
                    expect(requestBody).toContain("tag_names[]=alpha");
                    expect(requestBody).toContain("tag_names[]=beta");
                    expect(requestBody).toContain("tag_names[]=delta");
                });

                it('hides the x character on the tag', function() {
                    expect(view.$(".text-button").eq(0)).toHaveClass("disabled");
                });

                xit("displays the new tags", function() {
                    expect(view.$('a')).toContainTranslation('tags.edit_tags');
                });
            });

            describe("removing all the tags and clicking done", function() {
                beforeEach(function() {
                    view.$(".text-remove").click();
                    view.$('a.save_tags').click();
                });

                it("updates the 'edit_tags' text", function() {
                    expect(view.$(".edit_tags")).toContainTranslation("tags.add_tags");
                });
            });
        });
    });
});
