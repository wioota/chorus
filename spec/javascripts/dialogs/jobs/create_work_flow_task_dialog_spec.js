describe("chorus.dialogs.CreateWorkFlowTask", function() {
    describe('#render', function() {
        beforeEach(function() {
            this.magicFileName = "magic";
            this.workFlow = backboneFixtures.workfile.alpine();
            this.workspace = this.workFlow.workspace();
            this.workFlows = [this.workFlow, backboneFixtures.workfile.alpine({fileName: this.magicFileName})];

            this.workFlowSet = new chorus.collections.WorkfileSet(this.workFlows, {fileType: 'work_flow', workspaceId: this.workspace.id});
            this.dialog = new chorus.dialogs.CreateWorkFlowTask({collection: this.workFlowSet});
            this.dialog.render();
        });

        it("shows the correct title", function() {
            expect(this.dialog.$("h1")).toContainTranslation("create_job_task_dialog.title");
        });

        it("only fetches work flows", function() {
            var lastFetch = this.server.lastFetchFor(this.workFlowSet);
            expect(lastFetch.url).toHaveUrlPath('/workspaces/' + this.workFlowSet.models[0].workspace().id + '/workfiles');
            expect(lastFetch.url).toContainQueryParams({fileType: 'work_flow'});
        });

        context("when the collection fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(this.workFlowSet, this.workFlows);
            });

            it("shows the correct button name", function() {
                expect(this.dialog.$("button.submit")).toContainTranslation("create_job_task_dialog.submit");
            });

            it("doesn't have multiSelection", function() {
                expect(this.dialog.multiSelection).toBeFalsy();
            });

            describe("selecting an item", function() {
                beforeEach(function() {
                    this.dialog.$("ul li:eq(0)").click();
                });

                it("should mark the item selected", function() {
                    expect(this.dialog.$("ul li:eq(0)")).toHaveClass("selected");
                });
            });

            describe("search", function() {
                it("shows the correct placeholder", function() {
                    expect(this.dialog.$("input.chorus_search").attr("placeholder")).toMatchTranslation("job_task.work_flow.search_placeholder");
                });

                it("shows the correct item count label", function() {
                    expect(this.dialog.$(".count")).toContainTranslation("entity.name.WorkFlow", { count: 2 });
                });

                it("sets up search correctly", function() {
                    spyOn(this.dialog.collection, 'search');
                    this.dialog.$("input.chorus_search").val(this.magicFileName).trigger("keyup");
                    expect(this.dialog.collection.search).toHaveBeenCalled();
                });

                context("when the search fetch completes", function () {
                    beforeEach(function () {
                        this.dialog.$("input.chorus_search").val(this.magicFileName).trigger("keyup");
                        this.server.completeFetchFor(this.dialog.collection, [this.workFlows[1]]);
                    });

                    it("updates the count", function () {
                        expect(this.dialog.$(".list_content_details .count")).toContainTranslation("entity.name.WorkFlow", {count: 1});
                    });
                });
            });
        });
    });
});
