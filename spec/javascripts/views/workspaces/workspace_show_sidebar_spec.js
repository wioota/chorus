describe("chorus.views.WorkspaceShowSidebar", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.model = backboneFixtures.workspace({
            name: "A Cool Workspace",
            id: '123',
            image: {
                icon: "/system/workspaces/images/000/000/005/icon/workspaceimage.jpg",
                original: "/system/workspaces/images/000/000/005/original/workspaceimage.jpg"
            }
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view = new chorus.views.WorkspaceShowSidebar({model: this.model});
            this.view.render();
        });

        it("includes a workspace member list containing the workspace members", function() {
            expect(this.view.workspaceMemberList.collection).toEqual(this.model.members());
        });

        it("renders the name of the workspace in an h1", function() {
            expect(this.view.$("h1").text().trim()).toBe(this.model.get("name"));
            expect(this.view.$("h1").attr("title").trim()).toBe(this.model.get("name"));
        });

        context("the workspace has an image", function() {
            beforeEach(function() {
                spyOn(this.view.model, 'hasImage').andReturn(true);
                this.spyImg = spyOn(this.view.model, 'fetchImageUrl').andReturn("imageUrl1");
                this.view.render();
            });

            it("renders the workspace image", function() {
                expect(this.view.$("img.workspace_image").attr("src")).toContain("imageUrl1");
            });

            it("renders the sidebar when image is changed", function() {
                this.spyImg.andReturn("imageUrl2");
                this.view.model.trigger("image:change");
                expect(this.view.$("img.workspace_image").attr("src")).toContain("imageUrl2");
            });

            context("and the image is loaded", function() {
                beforeEach(function() {
                    spyOn(this.view, 'recalculateScrolling').andCallThrough();
                    this.view.render();
                    this.view.recalculateScrolling.reset();
                    this.view.$('.workspace_image').trigger('load');
                });

                it("calls recalculateScrolling", function() {
                    expect(this.view.recalculateScrolling).toHaveBeenCalled();
                });
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

        context("when kaggle is configured", function() {
            it("displays the find kaggle contributors link", function() {
                chorus.models.Config.instance().set({ kaggleConfigured: true });
                this.view.render();
                expect(this.view.$("a.kaggle")).toHaveHref(this.view.model.showUrl()+"/kaggle");
            });
        });

        context("when kaggle isnt configured", function() {
            it("doesnt display the find kaggle contributors link", function() {
                chorus.models.Config.instance().set({ kaggleConfigured: false });
                this.view.render();
                expect(this.view.$("a.kaggle")).not.toExist();
            });
        });

        context("when the current user has workspace admin permissions on the workspace", function() {
            beforeEach(function() {
                spyOn(this.model, "workspaceAdmin").andReturn(true);
                this.view.render();
            });

            it("has a link to edit workspace settings", function() {
                var linkText = this.view.$("a.edit_workspace").text().trim();
                expect(linkText).toMatchTranslation("actions.edit_workspace");
            });

            it("the link to Edit Workspace opens a Dialog", function () {
                var members = this.view.model.members();

                var launchModalSpy = spyOn(chorus.dialogs.EditWorkspace.prototype, 'launchModal');
                this.view.$('.edit_workspace').click();
                expect(launchModalSpy).not.toHaveBeenCalled();
                this.server.completeFetchFor(members);
                expect(launchModalSpy).toHaveBeenCalled();
            });

            it("has a link to delete the workspace", function() {
                expect(this.view.$("a.delete_workspace").text().trim()).toMatchTranslation("actions.delete_workspace");
            });

            it("has a link to edit members of the workspace", function() {
                expect(this.view.$("a.edit_workspace_members").text().trim()).toMatchTranslation("workspace.edit_members");
            });

            itBehavesLike.aDialogLauncher("a.delete_workspace", chorus.alerts.WorkspaceDelete);
            itBehavesLike.aDialogLauncher("a.edit_workspace_members", chorus.dialogs.WorkspaceEditMembers);

            context("and the workspace does not have a sandbox", function() {
                beforeEach(function() {
                    spyOn(this.model, "sandbox").andReturn(undefined);
                    this.view.render();
                });

                it("has a link to add a new sandbox", function() {
                    expect(this.view.$("a.new_sandbox").text().trim()).toMatchTranslation("sandbox.create_a_sandbox");
                });

                itBehavesLike.aDialogLauncher("a.new_sandbox", chorus.dialogs.SandboxNew);
            });

            context("and the workspace has a sandbox", function() {
                beforeEach(function() {
                    spyOn(this.model, "sandbox").andReturn(backboneFixtures.workspace().sandbox());
                    this.view.render();
                });

                it("does not have a link to add a new sandbox", function() {
                    expect(this.view.$("a.new_sandbox")).not.toExist();
                });
            });
        });

        context("when the current user is a member of the workspace, but not an admin/owner", function() {
            beforeEach(function() {
                spyOn(this.model, "workspaceAdmin").andReturn(false);
                spyOn(this.model, "canUpdate").andReturn(true);
                this.view.render();
            });

            it("has a link to edit the workspace's settings", function() {
                var linkText = this.view.$("a.edit_workspace").text().trim();
                expect(linkText).toMatchTranslation("actions.edit_workspace");
            });
        });

        context("when the current user is not a member of the workspace", function() {
            beforeEach(function() {
                spyOn(this.model, "workspaceAdmin").andReturn(false);
                spyOn(this.model, "canUpdate").andReturn(false);
                this.view.render();
            });

            it("has a link to view the workspace's settings", function() {
                var linkText = this.view.$("a.edit_workspace").text().trim();
                expect(linkText).toMatchTranslation("actions.view_workspace_settings");
            });

            it("does not have a link to delete the workspace", function() {
                expect(this.view.$("a.delete_workspace").length).toBe(0);
            });

            it("does not have a link to edit the workspace members", function() {
                expect(this.view.$("a.edit_workspace_members").length).toBe(0);
            });
        });

        context("when the workspace is archived", function() {
            beforeEach(function() {
                spyOn(this.model, "workspaceAdmin").andReturn(true);
                spyOn(this.view.model, "sandbox").andReturn(false);
                this.view.model.set({archivedAt: "2012-05-08 21:40:14"});
                this.view.render();
            });

            it("does not have the 'add or edit members link'", function() {
                expect(this.view.$('a.edit_workspace_members')).not.toExist();
            });

            it("does not have the 'add a sandbox' link", function() {
               expect(this.view.$('a.new_sandbox')).not.toExist();
            });

            it("does not have 'add a note' or 'ad an insight' link", function() {
               expect(this.view.$('a.new_note')).not.toExist();
               expect(this.view.$('a.new_insight')).not.toExist();
            });

            context("when kaggle is configured", function() {
                it("does not display the find kaggle contributor button", function() {
                    chorus.models.Config.instance().set({ kaggleConfigured: true });
                    this.view.render();
                    expect(this.view.$("a.kaggle")).not.toExist();
                });
            });
        });

        it("has a link to add a note", function() {
            expect(this.view.$("a.new_note").text().trim()).toMatchTranslation("actions.add_note");
        });

        it("has a link to add an insight", function() {
            expect(this.view.$("a.new_insight").text().trim()).toMatchTranslation("actions.add_insight");
        });

        it("should have a members list subview", function() {
            expect(this.view.$(".workspace_member_list")[0]).toBe(this.view.workspaceMemberList.el);
        });

        itBehavesLike.aDialogLauncher("a.new_note", chorus.dialogs.NotesNew);
        itBehavesLike.aDialogLauncher("a.new_insight", chorus.dialogs.InsightsNew);
    });

    describe("#post_render", function() {
        it("unhides the .after_image area after the .workspace_image loads", function() {
            this.view = new chorus.views.WorkspaceShowSidebar({model: this.model});
            spyOn($.fn, 'removeClass');
            $('#jasmine_content').append(this.view.el);
            this.view.render();
            expect($.fn.removeClass).not.toHaveBeenCalledWith('hidden');
            $(".workspace_image").trigger('load');
            expect($.fn.removeClass).toHaveBeenCalledWith('hidden');
            expect($.fn.removeClass).toHaveBeenCalledOnSelector('.after_image');
        });
    });
});
