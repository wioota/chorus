describe("chorus.views.AlpineWorkfileContentDetails", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.alpine();
        spyOn(this.model, 'canOpen').andReturn(true);
        spyOn(chorus.views.AlpineWorkfileContentDetails.prototype, "render").andCallThrough();
        this.view = new chorus.views.AlpineWorkfileContentDetails({ model: this.model });
        this.view.render();
    });

    it("fetches the workspace members", function(){
       expect(this.model.workspace().members()).toHaveBeenFetched();
    });

    it("re-renders the page when the members are fetched", function () {
        chorus.views.AlpineWorkfileContentDetails.prototype.render.reset();
        this.server.completeFetchFor(this.model.workspace().members());
        expect(chorus.views.AlpineWorkfileContentDetails.prototype.render).toHaveBeenCalled();
    });


    describe("render", function() {
        it("shows the 'Open File' button", function() {
            expect(this.view.$('a.open_file')).toContainTranslation('work_flows.show.open');
        });

        it("links the 'Open File' button to the Alpine page", function() {
            expect(this.view.$('a.open_file')).toHaveHref(this.model.workFlowShowUrl());
        });

        context("when the current user cannot open the workfile", function(){
            it("does not show the open file button", function(){
               this.model.canOpen.andReturn(false);
                this.view.render();
                expect(this.view.$(".open_file")).not.toExist();
            });
        });
    });
});
