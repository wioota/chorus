describe("chorus.views.WorkfileSidebar", function() {
    beforeEach(function(){
        this.workfile = rspecFixtures.workfile.sql();
    });

    context("when workfile is passed to setup", function() {
        beforeEach(function() {
            spyOn(chorus.views.Sidebar.prototype, "jumpToTop");
            spyOn(chorus.views.WorkfileSidebar.prototype, "recalculateScrolling").andCallThrough();
            this.workfile = rspecFixtures.workfile.text();
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile });
        });

        describe("setup", function() {
            it("fetches the ActivitySet for the workfile", function() {
                expect(this.workfile.activities()).toHaveBeenFetched();
            });

            xcontext("when the data tab resizes", function() {
                beforeEach(function() {
                    //TODO
                });

                it("calls recalculate scrolling", function() {
                    expect(this.view.recalculateScrolling).toHaveBeenCalled();
                });
            });
        });

        context("with a sql workfile", function() {
            beforeEach(function() {
                this.workfile = rspecFixtures.workfile.sql();
                this.view = new chorus.views.WorkfileSidebar({ model : this.workfile });

                this.view.model.fetch();
                this.view.model.workspace().fetch();

                this.server.completeFetchFor(this.workfile);
                this.server.completeFetchFor(this.workfile.workspace(), rspecFixtures.workspace({
                    id: this.workfile.workspace().id
                }));

                this.view.render();
            });

            it("displays a link to copy the workfile to another workspace", function() {
                var copyLink = this.view.$(".actions a[data-dialog=CopyWorkfile]");
                expect(copyLink).toExist();
                expect(copyLink).toHaveAttr("data-workspace-id", this.view.model.workspace().id);
                expect(copyLink).toHaveAttr("data-workfile-id", this.view.model.get("id"));
                expect(copyLink).toHaveAttr("data-active-only", 'true');
            });

            it("has an activities tab", function() {
                expect(this.view.$('.tab_control .activity_list')).toExist();
                expect(this.view.tabs.activity).toBeA(chorus.views.ActivityList);
            });
        });

        context("with a non-sql workfile", function() {
            beforeEach(function() {
                this.workfile = rspecFixtures.workfile.text({ versionInfo: { updatedAt: "2011-11-22T10:46:03Z" }});
                expect(this.workfile.isText()).toBeTruthy();

                this.view = new chorus.views.WorkfileSidebar({ model : this.workfile });

                this.view.model.fetch();
                this.view.model.workspace().fetch();

                this.server.completeFetchFor(this.workfile);
                this.server.completeFetchFor(this.workfile.workspace(), rspecFixtures.workspace({
                    id: this.workfile.workspace().id,
                    permission: ["read", "commenting", "update"]
                }));

                this.view.render();
            });

            it("should not have function or dataset tabs", function() {
                expect(this.view.$('.tab_control .activity_list')).toExist();
                expect(this.view.$('.tab_control .database_function_list')).not.toExist();
                expect(this.view.$('.tab_control .data_tab')).not.toExist();
            });

            it("displays a link to copy the workfile to another workspace", function() {
                var copyLink = this.view.$(".actions a[data-dialog=CopyWorkfile]");
                expect(copyLink).toExist();
                expect(copyLink).toHaveAttr("data-workspace-id", this.workfile.workspace().id);
                expect(copyLink).toHaveAttr("data-workfile-id", this.workfile.get("id"));
            });

            it("displays the filename", function() {
                expect(this.view.$(".fileName").text().trim()).toBe(this.workfile.get("fileName"));
            });

            it("displays the workfile's date", function() {
                expect(this.view.$(".updated_on").text().trim()).toBe("November 22");
            });

            it("displays the name of the person who updated the workfile", function() {
                expect(this.view.$(".updated_by").text().trim()).toBe(this.workfile.modifier().displayShortName());
            });

            it("links to the profile page of the modifier", function() {
                expect(this.view.$("a.updated_by").attr("href")).toBe(this.workfile.modifier().showUrl());
            });

            it("displays a link to delete the workfile", function() {
                var deleteLink = this.view.$(".actions a[data-alert=WorkfileDelete]");
                expect(deleteLink).toExist();
                expect(deleteLink).toHaveAttr("data-workspace-id", this.workfile.workspace().id);
                expect(deleteLink).toHaveAttr("data-workfile-id", this.workfile.get("id"));
            });

            it("displays a link to add a note", function() {
                var addLink = this.view.$(".actions a.dialog[data-dialog=NotesNew]");
                expect(addLink).toExist();
                expect(addLink).toHaveAttr("data-entity-type", "workfile");
                expect(addLink).toHaveAttr("data-entity-id", this.workfile.get("id"));
                expect(addLink).toHaveAttr("data-workspace-id", this.workfile.workspace().id);
                expect(addLink).toHaveAttr("data-allow-workspace-attachments", "true");
            });

            it("displays the activity list", function() {
                expect(this.view.$(".activity_list")).toExist();
            });
        });

        context("when it is a tableau workbook", function () {
            beforeEach(function () {
                this.view = new chorus.views.WorkfileSidebar({ model: this.workfile, showVersions: true });
                this.view.model.set({fileType: 'tableau_workbook'});
                this.view.render();
            });

            it("hide the copy and download links", function () {
                expect(this.view.$('.actions a.dialog[data-dialog=CopyWorkfile]')).not.toExist();
                expect(this.view.$('.actions a.download')).not.toExist();
            });

            it("hides the updated information", function () {
                expect(this.view.$('.info .updated')).not.toExist();
            });

            it('hides the version information', function(){
                expect(this.view.$('.version_list')).not.toExist();
            });
        });

        context("with an archived workspace", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.sql();
                this.model.loaded = false;
                this.model.workspace().loaded = false;
                this.view = new chorus.views.WorkfileSidebar({ model : this.model });

                this.model.fetch();
                this.model.workspace().fetch();

                this.server.completeFetchFor(this.model);
                this.server.completeFetchFor(this.model.workspace(), rspecFixtures.workspace({ archivedAt: "2012-05-08T21:40:14Z" }));

                this.view.render();
            });

            it("should not show the delete and add note links", function() {
                expect(this.view.$(".actions a[data-alert=WorkfileDelete]")).not.toExist();
                expect(this.view.$(".actions a[data-dialog=NotesNew]")).not.toExist();
            });

            it("should not show the functions or data tab", function() {
                expect(this.view.$(".tab_control .data_tab")).not.toExist();
                expect(this.view.$(".tab_control .database_function_list")).not.toExist();
            });
        });

        describe("when the model is invalidated", function() {
            it("fetches the activity set", function() {
                this.view.model.trigger("invalidated");
                expect(this.server.requests[0].url).toBe(this.view.collection.url());
            });
        });

        describe("when the activity list collection is changed", function() {
            beforeEach(function() {
                spyOn(this.view, "postRender"); // check for #postRender because #render is bound
                this.view.collection.trigger("changed");
            });

            it("re-renders", function() {
                expect(this.view.postRender).toHaveBeenCalled();
            });
        });

        describe("when the user is not a workspace member", function() {
            beforeEach(function() {
                this.workfile = rspecFixtures.workfile.text({ versionInfo: { updatedAt: "2011-11-22T10:46:03Z" }});
                this.view = new chorus.views.WorkfileSidebar({ model : this.workfile });

                this.view.model.fetch();
                this.view.model.workspace().fetch();

                this.server.completeFetchFor(this.workfile);
                this.server.completeFetchFor(this.workfile.workspace(), rspecFixtures.workspace({
                    id: this.workfile.workspace().id,
                    permission: ["read", "commenting"]
                }));

                this.view.render();
            });

            it("hides the link to delete the workfile", function() {
                var deleteLink = this.view.$(".actions a[data-alert=WorkfileDelete]");
                expect(deleteLink).not.toExist();
            });
        });

        describe('clicking the edit tags link', function(){
            beforeEach(function(){
                this.modalSpy = stubModals();
                this.view.$('.edit_tags').click();
            });

            it('opens the tag edit dialog', function(){
                expect(this.modalSpy).toHaveModal(chorus.dialogs.EditTags);
                expect(this.modalSpy.lastModal().collection.length).toBe(1);
                expect(this.modalSpy.lastModal().collection).toContain(this.workfile);
            });
        });
    });

    context("when showVersions is true", function() {
        beforeEach(function() {
            spyOn(chorus.views.Sidebar.prototype, "jumpToTop");
            spyOn(chorus.views.WorkfileSidebar.prototype, "recalculateScrolling").andCallThrough();
            this.workfile = rspecFixtures.workfile.text();
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile, showVersions: true });
        });

        it("fetches the versions", function() {
            expect(this.server.lastFetchFor(this.workfile.allVersions())).toBeDefined();
        });

        it("shows the versions", function() {
            expect(this.view.$('.version_list')).toExist();
        });

        describe("when the model is invalidated", function() {
            it("fetches the versions set", function() {
                this.view.model.trigger("invalidated");
                expect(this.server.lastFetch().url).toBe(this.view.allVersions.url());
            });
        });

        describe("when the version list collection is changed", function() {
            beforeEach(function() {
                spyOn(this.view, "postRender"); // check for #postRender because #render is bound
                this.view.allVersions.trigger("changed");
            });

            it("re-renders", function() {
                expect(this.view.postRender).toHaveBeenCalled();
            });
        });

        describe("when a workfile version is destroyed", function() {
            it("refetches the version list collection", function() {
                this.server.reset();
                chorus.PageEvents.broadcast("workfile_version:deleted", 3);
                expect(this.server.lastFetchFor(this.view.allVersions)).toBeDefined();
            });

            context("when the version destroyed is the currently displayed version", function() {
                it("redirects you to the workfile page", function() {
                    spyOn(chorus.router, "navigate");
                    chorus.PageEvents.broadcast("workfile_version:deleted", this.workfile.get("versionInfo").versionNum);
                    expect(chorus.router.navigate).toHaveBeenCalledWith(this.workfile.baseShowUrl());
                });
            });
        });
    });

    context('when showEditingLinks is true', function(){
        beforeEach(function(){
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile });
        });

        it('shows the editing links', function(){
            expect(this.view.$('.actions')).toContainTranslation('actions.add_note');
            expect(this.view.$('.actions')).toContainTranslation('workfile.delete.button');
        });
    });

    context('when showEditingLinks is false', function(){
        beforeEach(function(){
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile, showEditingLinks: false });
        });

        it('doesnt show the editing links', function(){
            expect(this.view.$('.actions')).not.toContainTranslation('actions.add_note');
            expect(this.view.$('.actions')).not.toContainTranslation('workfile.delete.button');
        });
    });

    context("when showVersions is not true", function() {
        beforeEach(function() {
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile});
        });

        it("does not fetch the versions", function() {
            expect(this.server.lastFetchFor(this.workfile.allVersions())).not.toBeDefined();
        });

        it("does not show the versions", function() {
            expect(this.view.$('.version_list')).not.toExist();
        });
    });

    context("when showSchemaTabs is true", function() {
        beforeEach(function() {
            stubDefer();
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile, showSchemaTabs: true});
        });

        it("shows the schema tabs", function() {
            expect(this.view.tabs.tabNames).toEqual(["data","database_function_list","activity"]);
        });
    });

    context("when showSchemaTabs is false", function() {
        beforeEach(function() {
            stubDefer();
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile});
        });

        it("does not show the schema tabs", function() {
            expect(this.view.tabs.tabNames).toEqual(["activity"]);
        });
    });

    context('when the workspace is archived', function(){
        beforeEach(function(){
            spyOn(this.workfile.workspace(), 'isActive').andReturn(false);
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile});
            this.view.render();
        });

        it("does not display a link 'add a note'", function() {
            expect(this.view.$el).not.toContainTranslation('actions.add_note');
        });

        it("does not display a delete link", function() {
            expect(this.view.$el).not.toContainTranslation('workfile.delete.button');
        });
    });

    context("when the workfile is not editable", function() {
        beforeEach(function() {
            spyOn(this.workfile.workspace(), 'canUpdate').andReturn(false);
            this.view = new chorus.views.WorkfileSidebar({ model: this.workfile});
            this.view.render();
        });

        it("does not display a delete link", function() {
            expect(this.view.$el).not.toContainTranslation('workfile.delete.button');
        });
    });

    describe(".buildFor", function() {
        it("instantiates an AlpineWorkfileSidebar view when the file is an alpine workfile", function() {
            var model = rspecFixtures.workfile.alpine();
            var view = chorus.views.WorkfileSidebar.buildFor({model: model});
            expect(view).toBeA(chorus.views.AlpineWorkfileSidebar);
        });

        it("instantiates an WorkfileSidebar view when the file a chorus workfile", function() {
            var model = rspecFixtures.workfile.sql();
            var view = chorus.views.WorkfileSidebar.buildFor({model: model});
            expect(view).toBeA(chorus.views.WorkfileSidebar);
            expect(view).not.toBeA(chorus.views.AlpineWorkfileSidebar);
        });

        it("passes options to the Sidebar constructor", function() {
            var model = rspecFixtures.workfile.sql();
            var view = chorus.views.WorkfileSidebar.buildFor({model: model, foo: 'bar'});
            expect(view.options.foo).toBe('bar');
        });
    });
});
