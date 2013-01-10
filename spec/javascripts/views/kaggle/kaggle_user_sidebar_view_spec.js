describe("chorus.views.KaggleUserSidebar", function () {
    beforeEach(function () {
        this.modalSpy = stubModals();
        this.collection = new chorus.collections.KaggleUserSet([rspecFixtures.kaggleUserSet().at(0)]);

        this.model = this.collection.at(0);
        this.workspace = rspecFixtures.workspace();
        this.view = new chorus.views.KaggleUserSidebar({workspace:this.workspace});
        this.view.setKaggleUser(this.model);
        this.view.render();
    });

    context("with no user", function() {
        beforeEach(function() {
            chorus.PageEvents.broadcast('kaggleUser:deselected', null);
        });

        it("does not show an username", function () {
            expect(this.view.$(".info .name").text()).toBe("");
        });

        it("does not show the user information sidebar", function() {
           expect(this.view.$('.tab_control')).toBeEmpty();
        });

        it("does not show the 'Compose message' link", function() {
           expect(this.view.$('.actions .sendMessage')).not.toExist();
        });
    });

    context("with a user", function () {
        beforeEach(function () {
            chorus.PageEvents.broadcast('kaggleUser:selected', this.model);
        });

        it("shows the user's name", function () {
            expect(this.view.$(".info .name")).toContainText(this.model.get("fullName"));
        });

        it("shows the user's location", function () {
            expect(this.view.$(".location")).toContainText(this.model.get("location"));
        });

        it("renders information inside the tabbed area", function () {
            expect(this.view.tabs.information).toBeA(chorus.views.KaggleUserInformation);
            expect(this.view.tabs.information.el).toBe(this.view.$(".tabbed_area .kaggle_user_information")[0]);
        });

        describe("sending a message", function () {
            beforeEach(function () {
            });

            it("links to the send message dialogue", function () {
                expect(this.view.$('a[data-dialog=ComposeKaggleMessage]')).toContainTranslation("actions.compose_kaggle_message");
            });

            it("opens the send message dialog", function () {
                var dialogLink = this.view.$(".actions a.sendMessage");
                expect(dialogLink.data("recipients").at(0).id).toBe(this.collection.at(0).id);
                expect(dialogLink.data("workspace")).toBe(this.workspace);
                expect(dialogLink.data("dialog")).toBe("ComposeKaggleMessage");
            });
        });
    });

    describe("when a Kaggle user is checked", function () {
        beforeEach(function () {
            this.checkedKaggleUsers = new chorus.collections.KaggleUserSet([rspecFixtures.kaggleUserSet().at(0)]);
            this.multiSelectSection = this.view.$(".multiple_selection");
            chorus.PageEvents.broadcast("kaggleUser:checked", this.checkedKaggleUsers);
        });

        it("displays the 'send message' link", function () {
            expect(this.multiSelectSection.find("a.sendMessage")).toContainTranslation("actions.send_kaggle_message");
        });

        describe("clicking the 'send message' link", function () {
            beforeEach(function () {
                this.modalSpy.reset();
                this.multiSelectSection.find("a.sendMessage").click();
            });

            it("launches the dialog for sending the message", function () {
                this.multiSelectSection.find("a.sendMessage").click();
                var dialog = this.modalSpy.lastModal();
                expect(dialog).toBeA(chorus.dialogs.ComposeKaggleMessage);
                expect(dialog.recipients).toBe(this.checkedKaggleUsers);
            });
        });
    });
});