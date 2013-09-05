describe("chorus.views.DashboardProjectList", function() {
    beforeEach(function() {
        this.workspace1 = backboneFixtures.workspace({ name: "Broccoli", owner: { firstName: 'Green', lastName: 'Giant' }, latestCommentList: [], summary: 'We are making sails!' });
        this.workspace2 = backboneFixtures.workspace({ name: "Camels", owner: { firstName: 'Andre', lastName: 'The Giant' }, latestCommentList: []});
        delete this.workspace2.attributes.summary;
        this.collection = new chorus.collections.WorkspaceSet([this.workspace1, this.workspace2]);
        this.collection.loaded = true;
        this.view = new chorus.views.DashboardProjectList({collection: this.collection});
    });

    describe("#render", function() {
        beforeEach(function() {
            spyOn($.fn, 'qtip');
            this.view.render();
        });

        it("displays the name of the workspace as a link", function() {
            expect(this.view.$(".name span").eq(0).text()).toBe("Broccoli");
            expect(this.view.$(".name").eq(0).attr('href')).toBe(this.workspace1.showUrl());

            expect(this.view.$(".name span").eq(1).text()).toBe("Camels");
            expect(this.view.$(".name").eq(1).attr('href')).toBe(this.workspace2.showUrl());
        });

        it("displays the name of the owners as a link", function() {
            expect(this.view.$(".owner span").eq(0).text()).toBe("Green Giant");
            expect(this.view.$(".owner").eq(0).attr('href')).toBe(this.workspace1.owner().showUrl());

            expect(this.view.$(".owner span").eq(1).text()).toBe("Andre The Giant");
            expect(this.view.$(".owner").eq(1).attr('href')).toBe(this.workspace2.owner().showUrl());
        });

        it("qtipifies info_icons", function () {
            var qtipCall = $.fn.qtip.calls[0];
            expect(qtipCall.object.selector).toBe(".icon-info-sign");
        });

        it("shows info icons only for projects with summaries", function () {
            expect(this.view.$('.info_icon').length).toBe(1);
        });
    });
});