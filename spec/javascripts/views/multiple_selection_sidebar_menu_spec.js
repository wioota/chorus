describe("chorus.views.MultipleSelectionSidebar", function() {
    beforeEach(function() {
        this.eventSpy = jasmine.createSpy('eventSpy');
        this.view = new chorus.views.MultipleSelectionSidebarMenu({
            actions: ['<span class="action_one">I am an action</span>'],
            selectEvent: "model:selected",
            actionEvents: {
                'click .action_one': this.eventSpy
            }
        });
        this.view.render();
        $('#jasmine_content').append(this.view.el);
    });

    context("when no models are selected", function() {
        it("is not visible", function() {
            expect(this.view.$el).not.toBeVisible();
        });
    });

    context("when a model is selected", function() {
        beforeEach(function() {
            chorus.PageEvents.broadcast("model:selected", new chorus.collections.Base([
                {}
            ]));
            this.view.render();
        });

        it("is visible", function() {
            expect(this.view.$el).toBeVisible();
        });

        it("it shows the number of models selected", function() {
            expect(this.view.$el).toContainText('1 Selected');
        });

        it("renders custom actions", function() {
            expect(this.view.$("li")).toContainText('I am an action');
        });

        it("binds custom events", function() {
            this.view.$(".action_one").click();
            expect(this.eventSpy).toHaveBeenCalled();
        });

        it("keeps event bindings separate", function() {
            var otherView = new chorus.views.MultipleSelectionSidebarMenu({
                actions: ['<span class="action_one">I am an action</span>'],
                selectEvent: "model:selected"
            });
            otherView.render();
            otherView.$(".action_one").click();
            expect(this.eventSpy).not.toHaveBeenCalled();
        });

        describe("clicking deselect all link", function() {
            beforeEach(function() {
                spyOn(chorus.PageEvents, "broadcast");
                this.view.$(".deselect_all").click();
            });

            it("broadcasts a selectNone event", function() {
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("selectNone");
            });
        });
    });
});