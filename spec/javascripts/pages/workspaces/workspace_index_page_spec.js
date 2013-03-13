describe("chorus.pages.WorkspaceIndexPage", function() {
    beforeEach(function() {
        this.workspaces = rspecFixtures.workspaceSet();
        this.page = new chorus.pages.WorkspaceIndexPage();
    });

    describe("#initialize", function() {
        it("has a helpId", function() {
            expect(this.page.helpId).toBe("workspaces");
        });

        it("has a sidebar", function() {
            expect(this.page.sidebar).toBeA(chorus.views.WorkspaceListSidebar);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.page.render();
        });

        describe("when the collection is loading", function() {
            it("should have a loading element", function() {
                expect(this.page.$(".loading")).toExist();
            });

            it("has a header", function() {
                expect(this.page.$("h1")).toExist();
            });
        });

        describe("when the collection is loaded", function() {
            beforeEach(function() {
                chorus.bindModalLaunchingClicks(this.page);
                this.server.completeFetchFor(this.page.collection, this.workspaces);
            });

            it("passes the multiSelect option to the list content details", function() {
                expect(this.page.mainContent.contentDetails.options.multiSelect).toBeTruthy();
            });

            it("displays an 'add workspace' button", function() {
                expect(this.page.$("button:contains('Create Workspace')")).toExist();
            });

            describe("when the workspace:selected event is triggered on the list view", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("workspace:selected", this.page.collection.at(3));
                });

                it("sets the model of the page", function() {
                    expect(this.page.model).toBe(this.page.collection.at(3));
                });
            });

            describe("multiple selection", function() {
                it("does not display the multiple selection section", function() {
                    expect(this.page.$(".multiple_selection")).toHaveClass("hidden");
                });

                context("when a row has been checked", function() {
                    beforeEach(function() {
                        chorus.PageEvents.broadcast("workspace:checked", this.page.collection.clone());
                    });

                    it("displays the multiple selection section", function() {
                        expect(this.page.$(".multiple_selection")).not.toHaveClass("hidden");
                    });

                    it("has an action to edit tags", function() {
                        expect(this.page.$(".multiple_selection a.edit_tags")).toExist();
                    });

                    describe("clicking the 'edit_tags' link", function() {
                        beforeEach(function() {
                            this.modalSpy = stubModals();
                            this.page.$(".multiple_selection a.edit_tags").click();
                        });

                        it("launches the dialog for editing tags", function() {
                            expect(this.modalSpy).toHaveModal(chorus.dialogs.EditTags);
                            expect(this.modalSpy.lastModal().collection).toBe(this.page.multiSelectSidebarMenu.selectedModels);
                        });
                    });
                });
            });
        });
    });

    describe("events", function() {
        beforeEach(function() {
            this.page = new chorus.pages.WorkspaceIndexPage();
            this.page.render();
            this.listView = this.page.mainContent.content;
            this.headerView = this.page.mainContent.contentHeader;
            spyOn(this.page.collection, 'fetch');
        });

        describe("when the 'choice:filter' event is triggered on the content header with 'all'", function() {
            it("fetches the unfiltered collection", function() {
                this.headerView.trigger("choice:filter", "all");
                expect(this.page.collection.attributes.active).toBeFalsy();
                expect(this.page.collection.fetch).toHaveBeenCalled();
            });
        });

        describe("when the 'choice:filter' event is triggered on the content header with 'active'", function() {
            it("fetches only the active collection", function() {
                this.headerView.trigger("choice:filter", "active");
                expect(this.page.collection.attributes.active).toBeTruthy();
                expect(this.page.collection.fetch).toHaveBeenCalled();
            });
        });
    });
});
