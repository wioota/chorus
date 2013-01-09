describe("chorus.views.TagBox", function() {
    var view, model;

    beforeEach(function() {
        model = rspecFixtures.workfile.sql({
            tags: []
        });
        model.loaded = false;
        model.fetch();
        view = new chorus.views.TagBox({model: model});
    });

    describe("#render", function() {
        beforeEach(function() {
            view.render();
        });

        context("when there are no tags", function() {
            it('shows the add tags link, textarea is hidden', function() {
                expect(view.$('a')).toContainTranslation('tags.add_tags');
                expect(view.$(".save_tags")).not.toExist();
            });
        });

        context("when there are already tags", function() {
            beforeEach(function() {
                model.set("tags", [{name: "alpha"}]);
                this.server.completeFetchFor(model);
                view.render();
            });

            it("should show the tags", function() {
                expect(view.$(".tag-list span")).toContainText("alpha");
                expect(view.$("textarea")).not.toExist();
            });

            it("should show tags without the x's", function() {
                expect(view.$(".text-remove")).not.toExist();
            });

            it("only shows the edit tags link", function() {
                expect(view.$(".save_tags")).not.toExist();
                expect(view.$(".edit_tags")).toExist();
                expect(view.$('a')).toContainTranslation('tags.edit_tags');
            });
        });
    });

    describe("escaping the tags", function() {
        beforeEach(function() {
            this.server.completeFetchFor(model);
            view.$('a.edit_tags').click();
            var input = view.$('input.tag_editor');
            input.val("s");
            var event = $.Event('keyup');
            event.keyCode = 115; // s
            input.trigger(event);
            waitsFor(_.bind(function() {
                return this.server.requests.length > 1;
            }, this));
        });

        it("should escape malicious tags", function() {
            this.server.lastFetch().succeed([{name: '<script>foo</script>'}]);
            expect($(view.el).html()).toContain("&lt;script&gt;foo&lt;/script&gt;");
            expect($(view.el).html()).not.toContain('<script>foo</script>');
        });
    });

    describe("when there are no tags", function() {
        beforeEach(function() {
            this.server.completeFetchFor(model);
            view.render();
        });
        context("clicking on add tags", function() {
            it('shows the textarea', function() {
                expect(view.$('.save_tags')).not.toExist();
                expect(view.$('.edit_tags')).toExist();
                view.$('a.edit_tags').click();
                expect(view.$('.save_tags')).toExist();
                expect(view.$('.edit_tags')).not.toExist();
                expect(view.$("input")).toExist();
            });
        });
    });

    describe("When there are some existing tags", function() {

        beforeEach(function() {
            model.set("tags", [{name: 'alpha'}, {name: 'beta'}, {name: 'gamma'}]);
            this.server.completeFetchFor(model);
            view.render();
        });

        it('shows the tag names', function() {
            expect(view.$el).toContainText("alpha");
            expect(view.$el).toContainText("beta");
            expect(view.$el).toContainText("gamma");
        });

        describe("When edit is clicked", function() {
            var input;

            beforeEach(function() {
                view.$('a.edit_tags').click();
                input = view.$('input.tag_editor');
            });

            it('shows the x character on the tags', function() {
                expect(view.$(".text-remove").eq(0)).toExist();
            });

            describe("when a valid tag is entered", function() {
                beforeEach(function() {
                    var tagName = _.repeat("a", 100);
                    enterTag(view, tagName);
                });

                it("creates a new tag", function() {
                    expect(view.$(".text-tag").length).toBe(4);
                });

                it("removes the text from the input", function() {
                    expect(input.val()).toBe("");
                });

                it("adds the tag to the model's tagset", function() {
                    expect(view.tags.at(3).name()).toEqual(_.repeat("a", 100));
                });
            });

            describe("when an empty tag is entered", function() {
                beforeEach(function() {
                    enterTag(view, "");
                });

                it("should not create a new tag", function() {
                    expect(view.$(".text-tag").length).toBe(3);
                    expect(view.model.tags().length).toBe(3);
                });
            });

            describe("when a tag with only white spaces is entered", function() {
                beforeEach(function() {
                    enterTag(view, "       ");
                });

                it("should not create a new tag", function() {
                    expect(view.$(".text-tag").length).toBe(3);
                    expect(view.model.tags().length).toBe(3);
                });
            });

            describe("when an invalid tag is entered", function() {
                var longString;
                beforeEach(function() {
                    longString = _.repeat("a", 101);
                    enterTag(view, longString);
                });

                it("does not create a new tag", function() {
                    expect(view.$(".text-tag").length).toBe(3);
                    expect(view.model.tags().length).toBe(3);
                });

                it("does not remove the text from the input", function() {
                    expect(input.val()).toBe(longString);
                });

                it("shows an error message", function() {
                    expect(input).toHaveClass("has_error");
                    expect(input.hasQtip()).toBeTruthy();
                });

                it("entering a valid tag clears the error class", function() {
                    enterTag(view, "new-tag");
                    expect(input).not.toHaveClass("has_error");
                });
            });

            describe("when a duplicate tag is entered", function() {
                beforeEach(function() {
                    enterTag(view, "alpha");
                });

                it("does not create the duplicate tag", function() {
                    expect(view.$(".text-tag").length).toBe(3);
                    expect(view.model.tags().length).toBe(3);
                });

                it("removes the text from the input", function() {
                    expect(input.val()).toBe("");
                });

            });

            describe("click done", function() {
                beforeEach(function() {
                    spyOn(view.tags, "save");
                    view.$('a.save_tags').click();
                });

                it("closes the text box", function() {
                    expect(view.$('.save_tags')).not.toExist();
                    expect(view.$('.edit_tags')).toExist();
                    expect(view.$("input")).not.toExist();
                });

                it('saves the tags', function() {
                    expect(view.tags.save).toHaveBeenCalled();
                });

                it('hides the x character on the tag', function() {
                    expect(view.$(".text-remove")).not.toExist();
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

            describe("typing a tag without hitting enter and then clicking done", function() {
                context("when the last tag is valid", function() {
                    beforeEach(function() {
                        view.$("input").val("hello");
                        view.$(".save_tags").click();
                    });

                    it("includes that last tag", function() {
                        expect(view.$el).toContainText("hello");
                        expect(view.tags.containsTag("hello")).toBe(true);
                    });

                    it("posts", function() {
                        expect(this.server.lastCreate()).toBeDefined();
                    });

                    it("does not update the model", function() {
                        expect(view.tags.length).toBe(4);
                    });
                });

                context("when the last tag is invalid", function() {
                    beforeEach(function() {
                        this.server.reset();
                        view.$("input").val("alpha");
                        view.$(".save_tags").click();
                    });

                    it("should not do post", function() {
                        expect(this.server.lastCreate()).toBeUndefined();
                    });

                    it("does not update the model", function() {
                       expect(model.tags().length).toBe(3);
                    });

                    it("doesn't reset the last tag on the next keyup", function() {
                        view.$("input").val("alpha2");
                        var keyup = $.Event("keyup");
                        view.$("input").trigger(keyup);
                        expect(view.$('input').val()).toBe("alpha2");
                    });
                });
            });
        });
    });
});
