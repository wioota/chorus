describe("chorus.views.TagsInput", function() {
    var view, tags, input;

    beforeEach(function() {
        tags = new chorus.collections.TaggingSet([
            {name: 'alpha'},
            {name: 'beta'},
            {name: 'gamma'}
        ]);
        view = new chorus.views.TagsInput({tags: tags});
        this.addedSpy = jasmine.createSpy("addedTag");
        this.removedSpy = jasmine.createSpy("removedTag");
        tags.on("add", this.addedSpy);
        tags.on("remove", this.removedSpy);
        view.render();
        input = view.$("input");

        stubDefer(); // don't defer auto-suggest server requests from textext to avoid test pollution
    });

    context("with no tags", function() {
        beforeEach(function() {
            view.tags.reset();
            view.render();
        });

        it("shows placeholder text", function() {
            expect(view.$("input").attr("placeholder")).toContainTranslation("tags.add_tags");
        });
    });

    it('shows the tag names', function() {
        expect(view.$el).toContainText("alpha");
        expect(view.$el).toContainText("beta");
        expect(view.$el).toContainText("gamma");
    });

    describe('clicking on the x', function() {
        it('shows the x character on the tags', function() {
            expect(view.$(".text-remove").eq(0)).toExist();
        });
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

    describe("when the first entered tag has a leading space", function() {
        beforeEach(function() {
            enterTag(view, " sigma");
        });

        it("discards the leading space", function() {
            expect(view.$(".text-tag .text-label")[3].innerHTML).toEqual("sigma");
            expect(this.addedSpy).toHaveBeenCalled();
        });

        it("does not allow adding the same tag with no space", function() {
            enterTag(view, "sigma");
            expect(this.addedSpy).toHaveBeenCalled();
            expect(this.addedSpy.callCount).toBe(1);
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

    describe("escaping the tags", function() {
        beforeEach(function() {
            this.server.reset();
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

        it("should escape malicious tags", function() {
            this.server.lastFetch().succeed([
                {name: '<script>foo</script>'}
            ]);
            expect($(view.el).html()).toContain("&lt;script&gt;foo&lt;/script&gt;");
            expect($(view.el).html()).not.toContain('<script>foo</script>');
        });
    });

    describe("displaying the list of suggested tags (autocomplete)", function() {
        beforeEach(function() {
            var input = view.$('input.tag_editor');
            input.val("s");
            var event = $.Event('keyup');
            event.keyCode = 115; // s
            input.trigger(event);
            waitsFor(_.bind(function() {
                return this.server.requests.length > 1;
            }, this));
        });

        it("escapes malicious tags", function() {
            this.server.lastFetch().succeed([
                {name: '<script>foo</script>'}
            ]);
            expect($(view.el).html()).toContain("&lt;script&gt;foo&lt;/script&gt;");
            expect($(view.el).html()).not.toContain('<script>foo</script>');
        });
    });

    describe("autocomplete", function() {
        var input;
        beforeEach(function() {
            var suggestions = rspecFixtures.tagSetJson({
                response: [{name: "alpha"}, {name: "beta"}, {name: "gamma"}]
            });
            $("#jasmine_content").append(view.el);
            view.tags.reset([{name: "alpha"}]);
            view.render();
            input = view.$("input.tag_editor");
            input.val("s");
            var event = $.Event('keyup');
            event.keyCode = 115; // s
            input.trigger(event);
            waitsFor(_.bind(function() {
                return this.server.requests.length > 0;
            }, this));
            runs(_.bind(function() {
                this.server.lastFetch().succeed(suggestions.response, suggestions.pagination);
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

            it("shows tag suggestions", function() {
                expect(view.$(".text-suggestion .text-label")).toContainText('beta');
                expect(view.$(".text-suggestion .text-label")).toContainText('gamma');
            });

            it("does not show existing tags", function() {
                expect(view.$(".text-suggestion .text-label")).not.toContainText('alpha');
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
});
