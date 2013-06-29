describe("chorus.views.KaggleUserSidebar", function () {
    beforeEach(function () {
        this.modalSpy = stubModals();
        this.collection = new chorus.collections.KaggleUserSet([backboneFixtures.kaggleUserSet().at(0)]);

        this.model = this.collection.at(0);
        this.workspace = backboneFixtures.workspace();
        this.view = new chorus.views.KaggleUserSidebar({workspace:this.workspace});
        this.view.setKaggleUser(this.model);
        this.view.render();
    });

    context("with no user", function() {
        beforeEach(function() {
            chorus.PageEvents.trigger('kaggle_user:deselected', null);
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
            chorus.PageEvents.trigger('kaggle_user:selected', this.model);
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

        itBehavesLike.aDialogLauncher(".actions a.sendMessage", chorus.dialogs.ComposeKaggleMessage);
    });
});