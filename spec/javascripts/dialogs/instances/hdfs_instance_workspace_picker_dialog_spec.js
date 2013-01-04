describe("chorus.dialogs.HdfsInstanceWorkspacePicker", function() {
    beforeEach(function() {
        setLoggedInUser({id: 4003});
        chorus.session.trigger("saved");

        stubModals();

        this.dialog = new chorus.dialogs.HdfsInstanceWorkspacePicker({
            model: rspecFixtures.hdfsDir({
                path: '/data',
                name: 'foo'
            }),
            activeOnly: true
        });
        this.dialog.launchModal();

        this.workspace1 = rspecFixtures.workspace({name: "Foo"});
        this.workspace2 = rspecFixtures.workspace({name: "Bar"});
        this.workspaces = new chorus.collections.WorkspaceSet([this.workspace1, this.workspace2]);
    });

    it("has the correct title and button", function() {
        expect(this.dialog.title).toMatchTranslation("hdfs_instance.workspace_picker.title");
        expect(this.dialog.submitButtonTranslationKey).toBe("hdfs_instance.workspace_picker.button");
    });

    context("when the fetch completes", function() {
        beforeEach(function() {
            this.server.lastFetch().succeed(this.workspaces.models);
        });

        it("renders all the workspaces", function() {
            expect(this.dialog.$("li").length).toBe(2);
        });

        context("when a workspace is selected", function() {
            beforeEach(function() {
                spyOn(this.dialog, "closeModal");
                spyOnEvent(this.dialog, "workspace:selected");
                this.dialog.$("li:eq(1)").click();
                this.dialog.$("button.submit").click();
            });

            it("triggers an event with the workspace model", function() {
                expect("workspace:selected").toHaveBeenTriggeredOn(this.dialog, [this.dialog.collection.at(1)]);
            });

            context("when the fetch completes", function() {
                beforeEach(function() {
                    spyOn(this.dialog, "launchSubModal");
                });

                it("does not display the error message", function() {
                    expect(this.dialog.$(".errors").text()).toBe("");
                });

                context("when the sandbox version is less than 4.2", function() {
                    it("displays the errors message and does not proceed", function() {
                        spyOnEvent(this.dialog, "workspace:selected");
                        this.dialog.selectedItem().sandbox().instance().set('version', '4.1');
                        this.dialog.$("button.submit").click();
                        expect(this.dialog.$(".errors").text()).toContainTranslation("hdfs_instance.gpdb_version.too_old_42");
                        expect("workspace:selected").not.toHaveBeenTriggeredOn(this.dialog, [this.dialog.selectedItem()]);
                    });
                });

                it("fetches the list of hdfs files", function() {
                    var hadoopInstanceId = this.dialog.model.get('hadoopInstance').id;
                    var fileId = this.dialog.model.id;
                    expect(this.server.lastFetch().url).toMatchUrl("/hadoop_instances/" + hadoopInstanceId + "/files/?id=" + fileId, {paramsToIgnore: ["page", "per_page"]});
                });

                context("when the hdfs entries fetch completes", function() {
                    beforeEach(function() {
                        var hdfsFiles = [
                            rspecFixtures.hdfsFile(),
                            rspecFixtures.hdfsFile(),
                            rspecFixtures.hdfsFile(),
                            rspecFixtures.hdfsDir()
                        ];
                        this.server.completeFetchFor(this.dialog.hdfsFiles, hdfsFiles);
                    });


                    it("filters out directories", function() {
                        expect(this.dialog.externalTableDialog.collection.length).toBe(3);
                    });

                    it("opens the Create External Table dialog, passing the workspace information", function() {
                        expect(this.dialog.launchSubModal).toHaveBeenCalledWith(this.dialog.externalTableDialog);
                        expect(this.dialog.externalTableDialog.options.workspaceId).toEqual(this.workspace1.id);
                        expect(this.dialog.externalTableDialog.options.workspaceName).toEqual("Foo");
                    });
                });

                context("when the hdfs entries fetch completes with no text files", function() {
                    beforeEach(function() {
                        var hdfsFiles2 = [
                            rspecFixtures.hdfsDirJson()
                        ];
                        this.server.completeFetchFor(this.dialog.hdfsFiles, hdfsFiles2);

                    });
                    it("displays error when the directory doesn't have any text files", function() {
                        expect(this.dialog.$(".errors").text()).toContainTranslation("hdfs_instance.no_text_files");
                    });

                    it("does not open the Create External Table dialog", function() {
                        expect(this.dialog.launchSubModal).not.toHaveBeenCalledWith(this.dialog.externalTableDialog);
                    });
                });

            });
        });
    });

    context("when csv_import:started event is triggered", function() {
        beforeEach(function() {
            spyOn(this.dialog, "closeModal");
            chorus.PageEvents.broadcast("csv_import:started");
        });
        it("closes the modal", function() {
            expect(this.dialog.closeModal).toHaveBeenCalled();
        });
    });
});
