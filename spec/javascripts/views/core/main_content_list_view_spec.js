describe("MainContentList", function() {
    beforeEach(function() {
        this.collection = rspecFixtures.userSet();
    });

    describe("#setup", function() {
        context("when no title override is provided", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User" });
            });

            it("sets the title of the content header to the plural of the model class", function() {
                expect(this.view.contentHeader.options.title).toBe("Users");
            });

            context("emptyTitleBeforeFetch option set", function() {
                beforeEach(function() {
                    this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", emptyTitleBeforeFetch: true });
                });

                it("should not display the title", function() {
                    expect(this.view.contentHeader.options.title).toBe(false);
                });
            });
        });

        context("when a title override is provided", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", title: "YES!" });
            });

            it("sets the title of the content header to the override", function() {
                expect(this.view.contentHeader.options.title).toBe("YES!");
            });
        });

        context("when a contentDetailsOptions hash is provided", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", contentDetailsOptions: {foo: "bar"} });
            });

            it("gets mixed in to the options for the list content details", function() {
                expect(this.view.contentDetails.options.foo).toBe("bar");
            });
        });

        context("when a contentOptions hash is provided", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", contentOptions: {foo: "bar"} });
            });

            it("gets mixed in to the content's options", function() {
                expect(this.view.content.options).toEqual({foo: "bar", collection: this.collection});
            });
        });

        context("when no contentDetails is provided", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User" });
            });

            it("creates a ListContentDetails view", function() {
                expect(this.view.contentDetails).toBeA(chorus.views.ListContentDetails);
            });
        });

        context("when a custom contentDetails is provided", function() {
            beforeEach(function() {
                this.contentDetails = stubView();
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", contentDetails: this.contentDetails });
            });

            it("does not create a ListContentDetails view", function() {
                expect(this.view.contentDetails).not.toBeA(chorus.views.ListContentDetails);
            });

            it("uses the custom contentDetails", function() {
                expect(this.view.contentDetails).toBe(this.contentDetails);
            });

            it("does not construct a contentFooter", function() {
                expect(this.view.contentFooter).toBeUndefined();
            });
        });

        context("when persistent is passed as an option", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ persistent: true, collection: this.collection, modelClass: "User" });
            });

            it("sets persistent as a property of the view", function() {
                expect(this.view.persistent).toBeTruthy();
            });
        });

        context("when contentHeader is provided", function() {
            beforeEach(function() {
                this.contentHeader = stubView();
                this.view = new chorus.views.MainContentList({ contentHeader: this.contentHeader, collection: this.collection, modelClass: "User" });
            });

            it("uses the provided view", function() {
                expect(this.view.contentHeader).toBe(this.contentHeader);
            });
        });

        context("search option", function() {
            beforeEach(function() {
                this.searchOptions = {foo: "bar"};
                this.view = new chorus.views.MainContentList({
                    collection: rspecFixtures.userSet(),
                    modelClass: "User",
                    search: this.searchOptions
                });
                this.view.render();
            });

            it("passes the search option to the list content details", function() {
                expect(this.view.contentDetails.options.search).toEqual({foo: "bar", list: $(this.view.content.el)});
            });
        });

        context("when checkable is true", function() {
            beforeEach(function() {
                this.collection = rspecFixtures.workfileSet();
                this.view = new chorus.views.MainContentList({
                    collection: this.collection,
                    modelClass: "Workfile",
                    checkable: true
                });
            });

            it("sets up a CheckableList as the content", function() {
                expect(this.view.content).toBeA(chorus.views.CheckableList);
            });

            it("actually renders the checkboxes", function() {
                this.view.render();
                expect(this.view.$("li input[type=checkbox]").length).toBe(this.collection.length);
            });
        });
    });
});
