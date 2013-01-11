describe("chorus.views.TagBox", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.sql({
            tags: []
        });
        this.model.loaded = false;
        this.model.fetch();
        this.view = new chorus.views.TagBox({model: this.model});

        stubDefer(); // don't defer auto-suggest server requests from textext to avoid test pollution
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        context("when there are no tags", function() {
            it('shows the add tags placeholder text in the textarea', function() {
                this.server.completeFetchFor(this.model);
                expect(this.view.$('input.tag_editor')).toExist();
                expect(this.view.$('input.tag_editor').attr("placeholder")).toContainTranslation('tags.add_tags');
            });
        });

        context("when there are already tags", function() {
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

            it('shows the x character on the tags', function() {
                expect(this.view.$(".text-remove").eq(0)).toExist();
            });

            it('shows the add tags ghost text and textarea', function() {
                expect(this.view.$('input.tag_editor')).toExist();
                expect(this.view.$('input').attr("placeholder")).toContainTranslation('tags.add_tags');
            });

            describe("when a valid tag is entered", function() {
                beforeEach(function() {
                    spyOn(this.view.tags, "save");
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

                it('saves the tags', function() {
                    expect(this.view.tags.save).toHaveBeenCalled();
                });
            });

            describe("when a tag is removed", function() {
                it('saves the tags', function() {
                    spyOn(this.view.tags, "save");
                    this.view.$('.text-remove:first').click();
                    expect(this.view.tags.save).toHaveBeenCalled();
                });
            });
        });
    });
});
