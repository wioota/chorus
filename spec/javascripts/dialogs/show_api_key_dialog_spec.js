describe("chorus.dialogs.ShowApiKey", function() {
    beforeEach(function() {
        setLoggedInUser();
        this.dialog = new chorus.dialogs.ShowApiKey();
        this.dialog.render();
    });

    describe("render", function() {
        it("shows the user's api key", function() {
            expect(this.dialog.$(".display_box")).toContainText(chorus.session.user().get("apiKey"));
        });

        it("shows the dialog's message content", function() {
            expect(this.dialog.$(".dialog_content")).toContainTranslation("users.show_api_key_dialog.content");
        });

        it("should have a 'Close' button", function() {
            expect(this.dialog.$("button.cancel")).toContainTranslation("actions.close");
        });
    });
});
