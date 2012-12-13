describe("chorus.dialogs.SandboxNew", function() {
    beforeEach(function() {
        this.workspace = rspecFixtures.workspace({id: 45});
        spyOn(chorus, "toast");
        spyOn(chorus, 'styleSelect');
        spyOn(chorus.router, 'reload');
        this.dialog = new chorus.dialogs.SandboxNew({ workspaceId: 45});
        this.server.completeFetchFor(this.workspace);
        this.dialog.render();
    });

    it("fetches the workspace", function() {
        expect(this.dialog.workspace).toHaveBeenFetched();
    });

    context("when the SchemaPicker triggers an error", function() {
        beforeEach(function() {
            var modelWithError = rspecFixtures.schemaSet();
            modelWithError.serverErrors = { fields: { a: { BLANK: {} } } };
            this.dialog.instanceMode.trigger("error", modelWithError);
        });

        it("shows the error", function() {
            expect(this.dialog.$('.errors')).toContainText("A can't be blank");
        });

        context("and then the schemaPicker triggers clearErrors", function() {
            it("clears the errors", function() {
                this.dialog.instanceMode.trigger("clearErrors");
                expect(this.dialog.$('.errors')).toBeEmpty();
            });
        })
    });

    context("clicking the submit button", function() {
        beforeEach(function() {
            this.sandbox = this.dialog.model;
            spyOn(this.sandbox, 'save').andCallThrough();
        });

        context("without schema selected yet", function() {
            beforeEach(function() {
                spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                    instance: "4",
                    database: "5",
                    schemaName: ""
                });
                this.dialog.instanceMode.trigger("change", "");
            });

            it("disables the submit button", function() {
                expect(this.dialog.$(".modal_controls button.submit")).toBeDisabled();
            });
        });

        it("sets the summary to empty string when it's null", function() {
            this.dialog.workspace.set({summary: null});
            spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                instance: "4",
                database: "5",
                schema: "6"
            });
            this.dialog.instanceMode.trigger("change", "6");
            this.dialog.$(".modal_controls button.submit").click();
            expect(this.server.lastUpdate().params()["workspace[summary]"]).toBe("");
        });

        it("retains the summary", function() {
            this.dialog.workspace.set({summary: "test"});
            spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                instance: "4",
                database: "5",
                schema: "6"
            });
            this.dialog.instanceMode.trigger("change", "6");
            this.dialog.$(".modal_controls button.submit").click();
            expect(this.server.lastUpdate().params()["workspace[summary]"]).toBe("test");
        });

        context("with a instance id, database id, and schema id", function() {
            context("with a schemaName, instanceId, databaseName in the model", function() {
                beforeEach(function() {
                    spyOn(this.dialog, 'closeModal');
                    spyOn(this.dialog.instanceMode, 'schemaId').andReturn("6");
                    this.dialog.workspace.set({
                        schemaName: "test_schema",
                        databaseName: "test_database",
                        instanceId: 1,
                        databaseId: 2
                    })
                    this.dialog.instanceMode.trigger("change", "6");
                    this.dialog.$(".modal_controls button.submit").click();
                });

                it("unsets the instanceId, schemaName, databaseName and databaseId on the sandbox", function() {
                    expect(this.dialog.workspace.get("schemaName")).toBeUndefined();
                    expect(this.dialog.workspace.get("databaseName")).toBeUndefined();
                    expect(this.dialog.workspace.get("databaseId")).toBeUndefined();
                    expect(this.dialog.workspace.get("instanceId")).toBeUndefined();
                    expect(this.dialog.workspace.get("summary")).toBeDefined();
                });

            })

            context("without a schemaName, instanceId, databaseName in the model", function() {
                beforeEach(function() {
                    spyOn(this.dialog, 'closeModal');
                    spyOn(this.dialog.instanceMode, 'schemaId').andReturn("6");
                    this.dialog.instanceMode.trigger("change", "6");
                    this.dialog.$(".modal_controls button.submit").click();
                });

                it("doesn't yet display a toast", function() {
                    expect(chorus.toast).not.toHaveBeenCalled();
                });

                it("changes the button text to 'Adding...'", function() {
                    expect(this.dialog.$(".modal_controls button.submit").text()).toMatchTranslation("sandbox.adding_sandbox");
                });

                it("sets the button to a loading state", function() {
                    expect(this.dialog.$(".modal_controls button.submit").isLoading()).toBeTruthy();
                });

                it("saves the workspace with the new sandbox id", function() {
                    expect(this.server.lastUpdate().params()["workspace[sandbox_id]"]).toBe("6");
                });

                it("sets the instance, schema and database on the sandbox", function() {
                    expect(this.dialog.workspace.get("sandboxId")).toBe('6');
                });

                describe("when save fails", function() {
                    beforeEach(function() {
                        this.server.lastUpdateFor(this.dialog.workspace).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
                    });

                    it("takes the button out of the loading state", function() {
                        expect(this.dialog.$(".modal_controls button.submit").isLoading()).toBeFalsy();
                    });

                    it("displays the error message", function() {
                        expect(this.dialog.$(".errors")).toContainText("A can't be blank");
                    });
                });

                describe("when the model is saved successfully", function() {
                    beforeEach(function() {
                        spyOnEvent(this.dialog.workspace, 'invalidated');
                        spyOn(this.dialog.workspace, 'fetch');
                        this.dialog.workspace.trigger("saved");
                    });

                    context("when the 'noReload' option is set", function() {
                        it("does not reload the page", function() {
                            chorus.router.reload.reset();
                            this.dialog.options.noReload = true;
                            this.sandbox.trigger("saved");
                            expect(chorus.router.reload).not.toHaveBeenCalled();
                        });
                    });

                    context("when the 'noReload' option is falsy", function() {
                        it("reloads the page", function() {
                            expect(chorus.router.reload).toHaveBeenCalled();
                        });
                    });

                    it("shows a toast message", function() {
                        expect(chorus.toast).toHaveBeenCalledWith("sandbox.create.toast");
                    });
                });
            })

        });

        context("with a instance id, database id, and schema name", function() {
            beforeEach(function() {
                spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                    instance: "4",
                    database: "5",
                    schemaName: "new_schema"
                });

                this.dialog.instanceMode.trigger("change", "new_schema");
                this.dialog.$("button.submit").click();
            });

            it("should set schema name on the model", function() {
                expect(this.dialog.workspace.get("schemaName")).toBe("new_schema");
            });

            it("saves the workspace with the new sandbox id", function() {
                expect(this.server.lastUpdate().params()["workspace[schema_name]"]).toBe("new_schema");
            });
        });

        context("with a database name and schema name", function() {
            beforeEach(function() {
                spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                    instance: "4",
                    databaseName: "new_database",
                    schemaName: "new_schema"
                });

                this.dialog.instanceMode.trigger("change", "new_schema");
                this.dialog.$("button.submit").click();
            });

            it("should set the database name and schema name on the model", function() {
                expect(this.dialog.workspace.get("databaseName")).toBe("new_database");
                expect(this.dialog.workspace.get("schemaName")).toBe("new_schema");
                expect(this.dialog.workspace.get("instanceId")).toBe("4");
            });

            it("saves the workspace with the new sandbox id", function() {
                expect(this.server.lastUpdate().params()["workspace[schema_name]"]).toBe("new_schema");
                expect(this.server.lastUpdate().params()["workspace[database_name]"]).toBe("new_database");
                expect(this.server.lastUpdate().params()["workspace[instance_id]"]).toBe("4");
            });
        });
    });
});
