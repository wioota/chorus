describe("chorus.views.TagsInput", function() {
    var view, tags;

    describe("showing tags", function() {
        beforeEach(function() {
            tags = new chorus.collections.TaggingSet([
                {name: "alpha"}
            ]);
            view = new chorus.views.TagsInput({tags: tags, editing: false});
            view.render();
        });

        it("should show the tags", function() {
            expect(view.$(".tag-list span")).toContainText("alpha");
            expect(view.$("textarea")).not.toExist();
        });

        it("shows the edit tags link", function() {
            expect(view.$("a.edit_tags")).toContainTranslation("tags.edit_tags");
        });

        it("clicking the edit tags link triggers startedEditing", function() {
            spyOnEvent(view, "startedEditing");
            view.$("a.edit_tags").click();
            expect("startedEditing").toHaveBeenTriggeredOn(view);
        });

        it("adds the editing class to the view", function() {
            view.$("a.edit_tags").click();
            expect(view.$el).toHaveClass('editing');
        });

        describe("escaping the tags", function() {
            beforeEach(function() {
                view.tags.reset();
                view.render();
                view.$('a.edit_tags').click();
                var input = view.$('input.tag_editor');
                input.val("s");
                var event = $.Event('keyup');
                event.keyCode = 115; // s
                input.trigger(event);
                waitsFor(_.bind(function() {
                    return this.server.requests.length > 0;
                }, this));
            });

            xit("should escape malicious tags", function() {
                this.server.lastFetch().succeed([
                    {name: '<script>foo</script>'}
                ]);
                expect($(view.el).html()).toContain("&lt;script&gt;foo&lt;/script&gt;");
                expect($(view.el).html()).not.toContain('<script>foo</script>');
            });
        });

        describe("with no tags", function() {
            beforeEach(function() {
                view.tags.reset();
                view.render();
            });

            it("shows the add tags link", function() {
               expect(view.$("a.edit_tags")).toContainTranslation("tags.add_tags");
            });
        });
    });

    describe("Editing tags", function() {
        var input;

        beforeEach(function() {
            tags = new chorus.collections.TaggingSet([
                {name: 'alpha'},
                {name: 'beta'},
                {name: 'gamma'}
            ]);
            view = new chorus.views.TagsInput({tags: tags, editing: true});
            this.addedSpy = jasmine.createSpy("addedTag");
            this.removedSpy = jasmine.createSpy("removedTag");
            tags.on("add", this.addedSpy);
            tags.on("remove", this.removedSpy);
            view.render();
            input = view.$("input");
        });

        it('shows the tag names', function() {
            expect(view.$el).toContainText("alpha");
            expect(view.$el).toContainText("beta");
            expect(view.$el).toContainText("gamma");
        });

        it('shows the x character on the tags', function() {
            expect(view.$(".text-remove").eq(0)).toExist();
        });

        describe("when a valid tag is entered", function() {
            var tagName;
            beforeEach(function() {
                tagName = _.repeat("a", 100);
                enterTag(view, tagName);
            });

            it("creates a new tag", function() {
                expect(view.$(".text-tag").length).toBe(4);
            });

            it("removes the text from the input", function() {
                expect(input.val()).toBe("");
            });

            it("adds the tag to the tagset", function() {
                expect(this.addedSpy).toHaveBeenCalled();
            });
        });

        describe("when an empty tag is entered", function() {
            beforeEach(function() {
                enterTag(view, "");
            });

            it("should not create a new tag", function() {
                expect(view.$(".text-tag").length).toBe(3);
                expect(this.addedSpy).not.toHaveBeenCalled();
            });
        });

        describe("when a tag with only white spaces is entered", function() {
            beforeEach(function() {
                enterTag(view, "       ");
            });

            it("should not create a new tag", function() {
                expect(view.$(".text-tag").length).toBe(3);
                expect(this.addedSpy).not.toHaveBeenCalled();
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
                expect(this.addedSpy).not.toHaveBeenCalled();
            });

            it("does not remove the text from the input", function() {
                expect(input.val()).toBe(longString);
            });

            it("shows an error message", function() {
                expect(input).toHaveClass("has_error");
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
                expect(this.addedSpy).not.toHaveBeenCalled();
            });

            it("removes the text from the input", function() {
                expect(input.val()).toBe("");
            });
        });

        describe("finishing the last tag", function() {
            context("when the last tag is valid", function() {
                beforeEach(function() {
                    spyOnEvent(view, "finishedEditing");
                    input.val("unentered_tag");
                    view.finishEditing();
                });

                it("returns true", function() {
                    expect("finishedEditing").toHaveBeenTriggeredOn(view);
                });

                it("adds the last tag", function() {
                    expect(this.addedSpy).toHaveBeenCalled();
                });

                it("does update the collection", function() {
                    expect(view.tags.length).toBe(4);
                });

                it("removes the editing class from the view", function() {
                    view.render();
                    expect(view.$el).not.toHaveClass('editing');
                });
            });

            context("when the last tag is invalid", function() {
                var tooLongTag;
                beforeEach(function() {
                    spyOnEvent(view, "finishedEditing");
                    tooLongTag = _.repeat("a", 101);
                    input.val(tooLongTag);
                    view.finishEditing();
                });

                it("returns false", function() {
                    expect("finishedEditing").not.toHaveBeenTriggeredOn(view);
                });

                it("does not add the last tag", function() {
                    expect(this.addedSpy).not.toHaveBeenCalled();
                });

                it("does not update the collection", function() {
                    expect(view.tags.length).toBe(3);
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
