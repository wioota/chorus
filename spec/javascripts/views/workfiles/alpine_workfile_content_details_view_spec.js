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
            expect(this.view.$('.open_file')).toContainTranslation('work_flows.show.open');
        });

        it("links the 'Open File' button to the Alpine page", function() {
            spyOn(chorus.router, 'navigate');
            this.view.$('.open_file').click();
            expect(chorus.router.navigate).toHaveBeenCalledWith(this.model.workFlowShowUrl());
        });

        context("when the execution location is a Greenplum database", function() {
            it("shows the data source name and database name", function() {
                var database = this.model.executionLocation();
                var dataSource = database.dataSource;
                expect(this.view.$('.execution_location')).toContainTranslation("work_flows.show.execution_location", {
                    dataSourceName: dataSource.name,
                    databaseName: database.name
                });
            });
        });

        context("when the execution location is null", function() {
            beforeEach(function() {
                this.model.set('executionLocation', null);
            });

            it("displays 'none' for the database", function() {
                expect(this.view.$('.execution_location')).toContainTranslation("work_flows.show.no_execution_location");
            });

            it('disables the Open File button', function() {
                expect(this.view.$('.open_file')).toBeDisabled();
            });
        });

        context("when the current user cannot open the workfile", function(){
            it("does not show the open file button", function(){
               this.model.canOpen.andReturn(false);
                this.view.render();
                expect(this.view.$(".open_file")).not.toExist();
            });
        });
    });

    context("when the user can edit the workfile", function() {
        describe("event handling", function() {
            describe("a.change_workfile_database:clicked", function() {
                beforeEach(function() {
                    spyOn(this.view, 'canUpdate').andReturn(true);
                    this.view.render();
                    spyOn(this.view, "changeWorkfileDatabase");
                    this.view.delegateEvents();
                    this.view.$("a.change_workfile_database").click();
                });
                it("calls the changeWorkfileDatabase function", function() {
                    expect(this.view.changeWorkfileDatabase).toHaveBeenCalled();
                });
            });
        });
    });

    context("when the user cannot edit the workfile", function() {
        it("does not show the change link", function() {
            spyOn(this.view, 'canUpdate').andReturn(false);
            this.view.render();
            expect(this.view.$('a.change_workfile_database')).not.toExist();
        });
    });

    describe("#changeWorkfileDatabase", function(){
        var modalSpy;
        beforeEach(function() {
            modalSpy = stubModals();

            this.event = jasmine.createSpyObj('click spy', ['preventDefault']);
            this.view.changeWorkfileDatabase(this.event);
        });

        it("prevents the default click behavior", function() {
            expect(this.event.preventDefault).toHaveBeenCalled();
        });

        it("shows the change schema dialog", function(){
            expect(modalSpy).toHaveModal(chorus.dialogs.ChangeWorkFlowExecutionLocation);
        });
    });

    describe("#canUpdate", function() {
        it("returns true when you can update the workspace", function() {
            spyOn(this.model.workspace(), 'canUpdate').andReturn(true);
            expect(this.view.canUpdate()).toBeTruthy();
        });

        it("returns false when you cannot update the workspace", function() {
            spyOn(this.model.workspace(), 'canUpdate').andReturn(false);
            expect(this.view.canUpdate()).toBeFalsy();
        });

        it("returns false when the workspace is archived", function() {
            spyOn(this.model.workspace(), 'canUpdate').andReturn(true);
            this.model.workspace().set('archivedAt', 'foobar');
            expect(this.view.canUpdate()).toBeFalsy();
        });

    });
});
