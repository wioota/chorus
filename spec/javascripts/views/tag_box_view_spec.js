describe("chorus.views.TagBox", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.sql({
            tags: []
        });
        this.model.loaded = false;
        this.model.fetch();
        this.view = new chorus.views.TagBox({model: this.model});
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        context("when there are no tags", function() {
            it('shows the add tags link, textarea is hidden', function() {
                expect(this.view.$('a')).toContainTranslation('tags.add_tags');
                expect(this.view.$(".save_tags")).not.toExist();
            });
        });

        context("when there are already tags", function() {
            beforeEach(function() {
                this.model.set("tags", [
                    {name: "alpha"}
                ]);
                this.server.completeFetchFor(this.model);
                this.view.render();
            });

            it("should show the tags", function() {
                expect(this.view.$(".tag-list span")).toContainText("alpha");
                expect(this.view.$("textarea")).not.toExist();
            });

            it("should show tags without the x's", function() {
                expect(this.view.$(".text-remove")).not.toExist();
            });

            it("only shows the edit tags link", function() {
                expect(this.view.$(".save_tags")).not.toExist();
                expect(this.view.$(".edit_tags")).toExist();
                expect(this.view.$('a')).toContainTranslation('tags.edit_tags');
            });
        });
    });

    describe("escaping the tags", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.model);
            this.view.$('a.edit_tags').click();
            var input = this.view.$('input.tag_editor');
            input.val("s");
            var event = $.Event('keyup');
            event.keyCode = 115; // s
            input.trigger(event);
            waitsFor(_.bind(function() {
                return this.server.requests.length > 1;
            }, this));
        });

        it("should escape malicious tags", function() {
            this.server.lastFetch().succeed([
                {name: '<script>foo</script>'}
            ]);
            expect($(this.view.el).html()).toContain("&lt;script&gt;foo&lt;/script&gt;");
            expect($(this.view.el).html()).not.toContain('<script>foo</script>');
        });
    });

    xdescribe("autocomplete", function() {
        var input;
        beforeEach(function() {
            var suggestions = rspecFixtures.tagSetJson();
            $("#jasmine_content").append(view.el);
            view.render();
            view.$('a.edit_tags').click();
            input = view.$("input.tag_editor");
            input.val("s");
            var event = $.Event('keyup');
            event.keyCode = 115; // s
            input.trigger(event);
            waitsFor(_.bind(function() {
                return this.server.requests.length > 0;
            }, this));
            runs(_.bind(function() {
                this.server.lastFetch().succeed(suggestions);
            }, this));
        });

        it("does not select anything by default", function() {
            expect(view.$(".text-list .text-selected")).not.toExist();
            expect(view.$(".text-dropdown").css("display")).not.toEqual('none');
        });

        describe("pressing down", function() {
            beforeEach(function() {
                var event = $.Event('keydown');
                event.keyCode = 40; // down arrow
                input.trigger(event);
            });

            it("selects the first suggested item", function() {
                expect(view.$(".text-suggestion:eq(0)")).toHaveClass('text-selected');
            });

            describe("pressing up from the top row", function() {
                beforeEach(function() {
                    var event = $.Event('keydown');
                    event.keyCode = 38; // up arrow
                    input.trigger(event);
                });

                it("closes the menu", function() {
                    expect(view.$(".text-dropdown").css("display")).toEqual('none');
                });
            });
        });
    });

    describe("when there are no tags", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.model);
            this.view.render();
        });
        context("clicking on add tags", function() {
            it('shows the textarea', function() {
                expect(this.view.$('.save_tags')).not.toExist();
                expect(this.view.$('.edit_tags')).toExist();
                this.view.$('a.edit_tags').click();
                expect(this.view.$('.save_tags')).toExist();
                expect(this.view.$('.edit_tags')).not.toExist();
                expect(this.view.$("input")).toExist();
            });
        });
    });

    describe("When there are some existing tags", function() {

        beforeEach(function() {
            this.model.set("tags", [
                {name: 'alpha'},
                {name: 'beta'},
                {name: 'gamma'}
            ]);
            this.server.completeFetchFor(this.model);
            this.view.render();
        });

        it('shows the tag names', function() {
            expect(this.view.$el).toContainText("alpha");
            expect(this.view.$el).toContainText("beta");
            expect(this.view.$el).toContainText("gamma");
        });

        describe("When edit is clicked", function() {
            beforeEach(function() {
                this.view.$('a.edit_tags').click();
            });

            it('shows the x character on the tags', function() {
                expect(this.view.$(".text-remove").eq(0)).toExist();
            });

            describe("when a valid tag is entered", function() {
                beforeEach(function() {
                    var tagName = _.repeat("a", 100);
                    enterTag(this.view, tagName);
                });

                it("creates a new tag", function() {
                    expect(this.view.$(".text-tag").length).toBe(4);
                });

                it("removes the text from the input", function() {
                    expect(this.view.$('input.tag_editor').val()).toBe("");
                });

                it("adds the tag to the model's tagset", function() {
                    expect(this.view.tags.at(3).name()).toEqual(_.repeat("a", 100));
                });
            });

            describe("click done", function() {
                beforeEach(function() {
                    spyOn(this.view.tags, "save");
                    this.view.$('a.save_tags').click();
                });

                it("closes the text box", function() {
                    expect(this.view.$('.save_tags')).not.toExist();
                    expect(this.view.$('.edit_tags')).toExist();
                    expect(this.view.$("input")).not.toExist();
                });

                it('saves the tags', function() {
                    expect(this.view.tags.save).toHaveBeenCalled();
                });

                it('hides the x character on the tag', function() {
                    expect(this.view.$(".text-remove")).not.toExist();
                });

                it("displays the new tags", function() {
                    expect(this.view.$('a')).toContainTranslation('tags.edit_tags');
                });
            });

            describe("removing all the tags and clicking done", function() {
                beforeEach(function() {
                    this.view.$(".text-remove").click();
                    this.view.$('a.save_tags').click();
                });

                it("updates the 'edit_tags' text", function() {
                    expect(this.view.$(".edit_tags")).toContainTranslation("tags.add_tags");
                });
            });

            describe("typing a tag without hitting enter and then clicking done", function() {
                context("when the last tag is valid", function() {
                    beforeEach(function() {
                        this.view.$("input").val("hello");
                        this.view.$(".save_tags").click();
                    });

                    it("includes that last tag", function() {
                        expect(this.view.$el).toContainText("hello");
                        expect(this.view.tags.containsTag("hello")).toBe(true);
                    });

                    it("posts", function() {
                        expect(this.server.lastCreate()).toBeDefined();
                    });

                    it("does not update the model", function() {
                        expect(this.view.tags.length).toBe(4);
                    });
                });

                context("when the last tag is invalid", function() {
                    beforeEach(function() {
                        this.server.reset();
                        this.view.$("input").val("alpha");
                        this.view.$(".save_tags").click();
                    });

                    it("should not post any tags", function() {
                        expect(this.server.lastCreate()).toBeUndefined();
                    });

                    it("does not update the model", function() {
                        expect(this.model.tags().length).toBe(3);
                    });
                });
            });
        });
    });
});
