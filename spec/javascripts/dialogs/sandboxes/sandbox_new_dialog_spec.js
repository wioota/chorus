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

        context("with a instance id, database id, and schema id", function() {
            beforeEach(function() {
                spyOn(this.dialog, 'closeModal');
                spyOn(this.dialog.instanceMode, 'schemaId').andReturn("6");
                spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                    instance: "4",
                    database: "5",
                    schema: "6"
                });

                this.dialog.instanceMode.trigger("change", "6");
                this.dialog.$("button.submit").click();
            });

            it("posts to the sandbox endpoint with the correct params", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                expect(this.server.lastCreate().params()['sandbox[schema_id]']).toBe('6');
                expect(this.server.lastCreate().params()['sandbox[database_id]']).toBe('5');
                expect(this.server.lastCreate().params()['sandbox[instance_id]']).toBe('4');
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
                expect(this.server.lastCreate().url).toBe("/workspaces/45/sandbox");
                expect(this.server.lastCreate().params()["sandbox[schema_id]"]).toBe('6');
            });

            describe("when save fails", function() {
                beforeEach(function() {
                    this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity({ fields: { a: { BLANK: {} } } });
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
                    this.dialog.model.trigger("saved");
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

            it("sets schema name on the sandbox", function() {
                expect(this.dialog.model.get("schemaName")).toBe("new_schema");
            });

            it("saves the workspace with the new sandbox name", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                expect(this.server.lastCreate().params()['sandbox[schema_name]']).toBe('new_schema');
                expect(this.server.lastCreate().params()['sandbox[schema_id]']).toBeUndefined();
                expect(this.server.lastCreate().params()['sandbox[database_id]']).toBe('5');
                expect(this.server.lastCreate().params()['sandbox[instance_id]']).toBe('4');
            });
        });

        context("with an instance id, database name and schema name", function() {
            beforeEach(function() {
                spyOn(this.dialog.instanceMode, 'fieldValues').andReturn({
                    instance: "4",
                    databaseName: "new_database",
                    schemaName: "new_schema"
                });

                this.dialog.instanceMode.trigger("change", "new_schema");
                this.dialog.$("button.submit").click();
            });

            it("sets the database name and schema name on the schema", function() {
                expect(this.dialog.model.get("databaseName")).toBe("new_database");
                expect(this.dialog.model.get("schemaName")).toBe("new_schema");
                expect(this.dialog.model.get("instanceId")).toBe("4");
            });

            it("saves the workspace with the new database and sandbox names", function() {
                expect(this.server.lastCreate().url).toBe('/workspaces/45/sandbox');
                expect(this.server.lastCreate().params()['sandbox[schema_name]']).toBe('new_schema');
                expect(this.server.lastCreate().params()['sandbox[schema_id]']).toBeUndefined();
                expect(this.server.lastCreate().params()['sandbox[database_name]']).toBe('new_database');
                expect(this.server.lastCreate().params()['sandbox[instance_id]']).toBe('4');
            });
        });
    });
});
