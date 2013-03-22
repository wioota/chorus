describe("chorus.alerts.Confirm", function() {
    beforeEach(function() {
        spyOn(chorus.alerts.Confirm.prototype, "confirmAlert");
        this.model = new chorus.models.Base({ id: "foo"});
        this.alert = new chorus.alerts.Confirm({ model : this.model });
        this.alert.title = "OH HAI";
        this.alert.text = "How are you?";
        this.alert.ok = "Do it!";
    });

    describe("#render", function() {
        beforeEach(function() {
            this.alert.render();
        });

        it("shows the submit button", function() {
            expect(this.alert.$("button.submit")).not.toHaveClass("hidden");
        });

        it("displays the 'ok' text on the submit button", function() {
            expect(this.alert.$("button.submit").text()).toBe("Do it!");
        });

        it('clicking the submit button calls confirmAlert', function() {
            this.alert.$('button.submit').click();
            expect(this.alert.confirmAlert).toHaveBeenCalled();
        });
    });

    describe("#revealed", function() {
        beforeEach(function() {
            spyOn($.fn, 'focus');
            this.alert.render();
        });

        it("focuses on the submit button", function() {
            this.alert.revealed();
            expect($.fn.focus).toHaveBeenCalled();
            expect($.fn.focus.mostRecentCall.object).toBe("button.submit");
        });
    });
});

