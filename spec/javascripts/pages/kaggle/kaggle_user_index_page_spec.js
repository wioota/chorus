describe("chorus.pages.KaggleUserIndexPage", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace({name: "kagSpace"});
        this.kaggleUsers = rspecFixtures.kaggleUserSet();
        this.page = new chorus.pages.KaggleUserIndexPage(this.workspace.id);
    });

    it("fetches the kaggle users", function() {
        expect(this.kaggleUsers).toHaveBeenFetched();
    });

    it("has a sidebar with the workspace", function() {
        expect(this.page.sidebar).toBeA(chorus.views.KaggleUserSidebar);
        expect(this.page.sidebar.workspace.id).toBe(this.workspace.id);
    });

    context("Kaggle user list is unreachable", function() {
        beforeEach(function() {
            spyOn(Backbone.history, "loadUrl");
            this.server.lastFetchFor(this.kaggleUsers).failUnprocessableEntity({
                record: 'KAGGLE_API_UNREACHABLE'
            });
        });

        it("redirects to the unprocessable entity page", function() {
            expect(Backbone.history.loadUrl).toHaveBeenCalledWith('/unprocessableEntity');
            expect(chorus.pageOptions.title).toMatchTranslation('record_error.KAGGLE_API_UNREACHABLE_title');
            expect(chorus.pageOptions.text).toMatchTranslation('record_error.KAGGLE_API_UNREACHABLE');
        });
    });

    context("after the workspace has loaded successfully", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace, this.workspace);
        });

        it("displays the breadcrumbs", function() {
            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0)").text().trim()).toBe(t("breadcrumbs.home"));

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/workspaces");
            expect(this.page.$(".breadcrumb:eq(1)").text().trim()).toBe(t("breadcrumbs.workspaces"));

            expect(this.page.$(".breadcrumb:eq(2) a").attr("href")).toBe(this.workspace.showUrl());
            expect(this.page.$(".breadcrumb:eq(2)").text().trim()).toBe("kagSpace");

            expect(this.page.$(".breadcrumb:eq(3)").text().trim()).toBe("Kaggle");
        });

        it("shows the kaggle header", function() {
            expect(this.page.$(".content_header .summary")).toContainTranslation("kaggle.summary", {kaggleLink: 'Kaggle'});
        });

        describe("multiple selection", function() {
            it("does not display the multiple selection section", function() {
                expect(this.page.$(".multiple_selection")).toHaveClass("hidden");
            });

            context("when a row has been checked", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("kaggle_user:checked", this.kaggleUsers.clone());
                });

                it("displays the multiple selection section", function() {
                    expect(this.page.$(".multiple_selection")).not.toHaveClass("hidden");
                });

                it("has an action to send message to kaggle users", function() {
                    expect(this.page.$(".multiple_selection a.send_message")).toExist();
                });

                describe("clicking the 'send_message' link", function() {
                    beforeEach(function() {
                        this.modalSpy = stubModals();
                        this.page.$(".multiple_selection a.send_message").click();
                    });

                    it("launches the dialog for sending a kaggle message", function() {
                        expect(this.modalSpy).toHaveModal(chorus.dialogs.ComposeKaggleMessage);
                        expect(this.modalSpy.lastModal().recipients).toBe(this.page.multiSelectSidebarMenu.selectedModels);

                    });
                });
            });
        });
    });

    describe("when the users and the workspace have loaded", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.workspace);
            this.server.completeFetchFor(this.kaggleUsers);
        });

        it("sets up the content details", function() {
            expect(this.page.mainContent.contentDetails).toBeA(chorus.views.KaggleUserListContentDetails);
            expect(this.page.mainContent.contentDetails.collection).toBeA(chorus.collections.KaggleUserSet);
        });

        it("shows the kaggle users", function() {
            expect(this.page.$(".kaggle_user_item").length).toBe(this.kaggleUsers.length);
        });

        it("shows the kaggle user sidebar", function() {
            expect(this.page.$(".kaggle_user_sidebar")).toExist();
        });
    });

    describe("filtering the kaggle users", function() {
        beforeEach(function() {
            this.server.reset();
            var filterCollection = new chorus.collections.KaggleFilterSet([
                new chorus.models.KaggleFilter(),
                new chorus.models.KaggleFilter()
            ]);
            spyOn(filterCollection.at(1), 'filterParams').andReturn(null);
            spyOn(filterCollection.at(0), 'filterParams').andReturn("someValue");
            chorus.PageEvents.broadcast("filterKaggleUsers", filterCollection);
        });

        it("sends a request for the filtered users", function() {
            expect(this.page.collection).toHaveBeenFetched();
            var url = this.server.lastFetchFor(this.page.collection).url;
            expect(url).toContainQueryParams({'filters[]': 'someValue'});
        });
    });
});