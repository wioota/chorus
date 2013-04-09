jasmine.sharedExamples.PopupMenu = function(linkSelector, menuSelector) {
    describe("when another popup is opened on the page", function() {
        beforeEach(function() {
            this.view.render();
            this.view.$(linkSelector).click();
            expect(this.view.$(menuSelector)).not.toHaveClass("hidden");
            chorus.PageEvents.broadcast("popup_menu:opened", $(''));
        });

        it("dismisses the popup", function() {
            expect(this.view.$(menuSelector)).toHaveClass("hidden");
        });
    });
};