describe("chorus.dialogs.CreateWorkFlowTask", function() {
    beforeEach(function() {
        this.job = backboneFixtures.job();
        this.magicFileName = "magic";
        this.workFlow = backboneFixtures.workfile.alpine();
        this.workspace = this.workFlow.workspace();
        this.workFlows = [this.workFlow, backboneFixtures.workfile.alpine({fileName: this.magicFileName})];

        this.workFlowSet = new chorus.collections.WorkfileSet(this.workFlows, {fileType: 'work_flow', workspaceId: this.workspace.id});
        this.dialog = new chorus.dialogs.CreateWorkFlowTask({job: this.job, collection: this.workFlowSet});
        this.dialog.render();
    });

    describe('#render', function() {
        it("shows the correct title", function() {
            expect(this.dialog.$("h1")).toContainTranslation("create_job_task_dialog.add_title");
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
                expect(this.dialog.$("button.submit")).toContainTranslation("create_job_task_dialog.add");
            });

            it("doesn't have multiSelection", function() {
                expect(this.dialog.multiSelection).toBeFalsy();
            });

            describe("selecting an item", function() {
                it("should mark the item selected", function() {
                    this.dialog.$("ul li:eq(0)").click();
                    expect(this.dialog.$("ul li:eq(0)")).toHaveClass("selected");
                });

                it("enables the form", function () {
                    var submitButton = this.dialog.$("button.submit");
                    expect(submitButton).toBeDisabled();
                    this.dialog.$("ul li:eq(0)").click();
                    expect(submitButton).toBeEnabled();
                });


                context("when submitting the form", function () {
                    beforeEach(function () {
                        this.dialog.$("ul li:eq(0)").click();
                        this.dialog.$("button.submit").click();
                    });

                    it("posts to the correct url", function () {
                        var url = this.server.lastCreateFor(this.dialog.model).url;
                        expect(url).toBe(this.dialog.model.url());
                    });

                    it("submits the correct fields", function () {
                        var params = this.server.lastCreateFor(this.dialog.model).params();
                        expect(params['job_task[action]']).toBe('run_work_flow');
                        expect(params['job_task[work_flow_id]']).toBe(this.workFlow.get('id'));
                    });

                    context("when the save succeeds", function () {
                        beforeEach(function () {
                            spyOn(this.dialog, "closeModal");
                            spyOn(chorus, "toast");
                            spyOn(this.dialog.job, 'trigger');
                            this.server.lastCreateFor(this.dialog.model).succeed();
                        });

                        it("closes the modal", function () {
                            expect(this.dialog.closeModal).toHaveBeenCalled();
                        });

                        it("should create a toast", function () {
                            expect(chorus.toast).toHaveBeenCalledWith(this.dialog.message);
                        });

                        it("invalidates the job", function () {
                            expect(this.dialog.job.trigger).toHaveBeenCalledWith('invalidated');
                        });
                    });
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
