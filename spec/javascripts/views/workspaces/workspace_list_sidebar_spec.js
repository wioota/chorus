describe("chorus.views.WorkspaceListSidebar", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.view = new chorus.views.WorkspaceListSidebar();
    });

    context("no workspaces exist", function() {
        it("does not have actions to add a note and to add an insight", function() {
            expect(this.view.$(".actions a.new_note")).not.toExist();
            expect(this.view.$(".actions a.new_insight")).not.toExist();
        });
    });

    context("a workspace exists", function() {
        beforeEach(function() {
            this.workspace = backboneFixtures.workspace();

            chorus.PageEvents.trigger("workspace:selected", this.workspace);
        });

        it("displays the workspace name", function() {
            expect(this.view.$(".name")).toContainText(this.workspace.get("name"));
        });

        context("the workspace has an image", function() {
            beforeEach(function() {
                spyOn(this.view.model, 'hasImage').andReturn(true);
                spyOn(this.view.model, 'fetchImageUrl').andReturn("/user/456/image");
                this.view.render();
            });

            it("renders the workspace image", function() {
                expect(this.view.$("img.workspace_image").attr("src")).toContain("/user/456/image");
            });
        });

        context("the workspace does not have an image", function() {
            beforeEach(function() {
                spyOn(this.view.model, 'hasImage').andReturn(false);
                spyOn(this.view.model, 'fetchImageUrl').andReturn("/party.gif");
                this.view.render();
            });

            it("does not render the workspace image", function() {
                expect(this.view.$("img.workspace_image")).not.toExist();
            });
        });

        it("has the workspace member list", function() {
            expect(this.view.$(".workspace_member_list")[0]).toBe(this.view.workspaceMemberList.el);
        });

        describe("when the activity fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchFor(this.workspace.activities());
            });

            it("renders an activity list inside the tabbed area", function() {
                expect(this.view.tabs.activity).toBeA(chorus.views.ActivityList);
                expect(this.view.tabs.activity.el).toBe(this.view.$(".tabbed_area .activity_list")[0]);
            });
        });

        it("has actions to add a note and to add an insight", function() {
            expect(this.view.$(".actions a.new_note")).toContainTranslation("actions.add_note");
            expect(this.view.$(".actions a.new_insight")).toContainTranslation("actions.add_insight");
        });

        context("clicking the add note link", function() {
            beforeEach(function() {
                this.modalSpy.reset();
                $('#jasmine_content').append(this.view.$el);
                chorus.page = this.view;
                this.view.$("a.new_note").click();
            });

            it("should launch the NotesNew dialog once", function() {
                expect(this.modalSpy).toHaveModal(chorus.dialogs.NotesNew);
                expect(this.modalSpy.modals().length).toBe(1);
            });
        });

        context("clicking the add insights link", function() {
            beforeEach(function() {
                this.modalSpy.reset();
                $('#jasmine_content').append(this.view.$el);
                chorus.page = this.view;
                this.view.$("a.new_insight").click();
            });

            it("should launch the InsightsNew dialog once", function() {
                expect(this.modalSpy).toHaveModal(chorus.dialogs.InsightsNew);
                expect(this.modalSpy.modals().length).toBe(1);
            });
        });

        describe('clicking the edit tags link', function(){
            beforeEach(function(){
                this.view.$('.edit_tags').click();
            });

            it('opens the tag edit dialog', function(){
                expect(this.modalSpy).toHaveModal(chorus.dialogs.EditTags);
                expect(this.modalSpy.lastModal().collection.length).toBe(1);
                expect(this.modalSpy.lastModal().collection).toContain(this.workspace);
            });
        });
    });
});
