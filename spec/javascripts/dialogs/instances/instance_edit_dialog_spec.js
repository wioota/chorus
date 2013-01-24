describe("chorus.dialogs.InstanceEdit", function() {
    beforeEach(function() {
        this.instance = rspecFixtures.gpdbDataSource({
            name: "pasta",
            host: "greenplum",
            port: "8555",
            description: "it is a food name",
            dbName: "postgres"
        });
        this.dialog = new chorus.dialogs.InstanceEdit({ instance: this.instance });
    });

    it("should make a copy of the source model", function() {
        expect(this.dialog.model).not.toBe(this.instance);
        expect(this.dialog.model.attributes).toEqual(this.instance.attributes);
    });

    describe("#render", function() {
        describe("when editing a greenplum instance", function() {
            beforeEach(function() {
                this.dialog.model.set({ entityType: "gpdb_data_source"});
                this.dialog.render();
            });

            it("Field called 'name' should be editable and pre populated", function() {
                expect(this.dialog.$("input[name=name]").val()).toBe("pasta");
                expect(this.dialog.$("input[name=name]").prop("disabled")).toBeFalsy();
            });

            it("Field called 'description' should be editable and pre populated", function() {
                expect(this.dialog.$("textarea[name=description]").val()).toBe("it is a food name");
                expect(this.dialog.$("textarea[name=description]").prop("disabled")).toBeFalsy();
            });

            it("Field called 'host' should be editable and pre populated", function() {
                expect(this.dialog.$("input[name=host]").val()).toBe("greenplum");
                expect(this.dialog.$("input[name=host]").prop("disabled")).toBeFalsy();
            });

            it("Field called 'port' should be editable and pre populated", function() {
                expect(this.dialog.$("input[name=port]").val()).toBe("8555");
                expect(this.dialog.$("input[name=port]").prop("disabled")).toBeFalsy();
            });

            it("has a 'database' field that is pre-populated", function() {
                expect(this.dialog.$("input[name='dbName']").val()).toBe("postgres");
                expect(this.dialog.$("label[name='dbName']").text()).toMatchTranslation("instances.dialog.database_name");
                expect(this.dialog.$("input[name='dbName']").prop("disabled")).toBeFalsy();
            });
        });

        describe("when editing a hadoop instance", function() {
            beforeEach(function() {
                this.dialog.model.set({ username: "user", groupList: "hadoop"});
                this.dialog.model = new chorus.models.HadoopInstance(this.dialog.model.attributes);
                this.dialog.render();
            });

            it("has a pre-populated and enabled 'name' field", function() {
                expect(this.dialog.$("input[name=name]").val()).toBe("pasta");
                expect(this.dialog.$("input[name=name]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'description' field", function() {
                expect(this.dialog.$("textarea[name=description]").val()).toBe("it is a food name");
                expect(this.dialog.$("textarea[name=description]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'host' field", function() {
                expect(this.dialog.$("input[name=host]").val()).toBe("greenplum");
                expect(this.dialog.$("input[name=host]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'port' field", function() {
                expect(this.dialog.$("input[name=port]").val()).toBe("8555");
                expect(this.dialog.$("input[name=port]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'HDFS account' field", function() {
                expect(this.dialog.$("input[name=username]").val()).toBe("user");
                expect(this.dialog.$("input[name=username]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'group list' field", function() {
                expect(this.dialog.$("input[name=groupList]").val()).toBe("hadoop");
                expect(this.dialog.$("input[name=groupList]").prop("disabled")).toBeFalsy();
            });
        });

        describe("when editing a gnip instance", function() {
            beforeEach(function() {
                this.instance = rspecFixtures.gnipInstance({
                    name: "myGnip",
                    username: "me@fun.com",
                    streamUrl: "https://some.thing.com",
                    description: "a gnip instance"
                });
                this.dialog = new chorus.dialogs.InstanceEdit({ instance: this.instance });

                this.dialog.model = new chorus.models.GnipInstance(this.dialog.model.attributes);
                this.dialog.render();
            });

            it("has a pre-populated and enabled 'name' field", function() {
                expect(this.dialog.$("input[name=name]").val()).toBe("myGnip");
                expect(this.dialog.$("input[name=name]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'description' field", function() {
                expect(this.dialog.$("textarea[name=description]").val()).toBe("a gnip instance");
                expect(this.dialog.$("textarea[name=description]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'streamUrl' field", function() {
                expect(this.dialog.$("input[name=streamUrl]").val()).toBe("https://some.thing.com");
                expect(this.dialog.$("input[name=streamUrl]").prop("disabled")).toBeFalsy();
            });

            it("has a pre-populated and enabled 'username' field", function() {
                expect(this.dialog.$("input[name=username]").val()).toBe("me@fun.com");
                expect(this.dialog.$("input[name=username]").prop("disabled")).toBeFalsy();
            });

            it("shows an empty 'password' field", function() {
                expect(this.dialog.$("input[name=password]").val()).toBe("");
                expect(this.dialog.$("input[name=password]").prop("disabled")).toBeFalsy();
            });
        });
    });

    describe("saving", function() {
        beforeEach(function() {
            this.dialog.model.set({ entity_type: "gpdb_data_source"});
            this.dialog.render();

            spyOn(this.dialog, "closeModal");
            spyOn(chorus, "toast");

            this.dialog.$("input[name=name]").val(" test1 ");
            this.dialog.$("input[name=port]").val("8555");
            this.dialog.$("input[name=host]").val(" testhost ");
            this.dialog.$("input[name=dbName]").val(" not_postgres ");
            this.dialog.$("textarea[name=description]").val("  instance   ");
        });

        it("puts the button in 'loading' mode", function() {
            spyOn(this.dialog.model, "save");
            this.dialog.$("button[type=submit]").submit();
            expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
        });

        it("should call the save method", function() {
            spyOn(this.dialog.model, "save");
            this.dialog.$("button[type=submit]").submit();
            expect(this.dialog.model.save).toHaveBeenCalled();
        });

        it("should call save with the right parameters", function() {
            spyOn(this.dialog.model, "save").andCallThrough();
            this.dialog.$("button[type=submit]").submit();

            expect(this.dialog.model.save.argsForCall[0][0].name).toBe("test1");
            expect(this.dialog.model.save.argsForCall[0][0].port).toBe("8555");
            expect(this.dialog.model.save.argsForCall[0][0].host).toBe("testhost");
            expect(this.dialog.model.save.argsForCall[0][0].description).toBe("instance");
            expect(this.dialog.model.save.argsForCall[0][0].dbName).toBe("not_postgres");
        });

        it("changes the text on the upload button to 'saving'", function() {
            spyOn(this.dialog.model, "save");
            this.dialog.$("button[type=submit]").submit();
            expect(this.dialog.$("button.submit").text()).toMatchTranslation("instances.new_dialog.saving");
        });

        it("disables the cancel button", function() {
            spyOn(this.dialog.model, "save");
            this.dialog.$("button[type=submit]").submit();
            expect(this.dialog.$("button.cancel")).toBeDisabled();
        });

        context("with a hadoop instance", function() {
            beforeEach(function() {
                this.dialog.model = new chorus.models.HadoopInstance();
                this.dialog.render();
                this.dialog.$("input[name=name]").val("test3");
                this.dialog.$("input[name=port]").val("8557");
                this.dialog.$("input[name=host]").val("testhost3");
                this.dialog.$("input[name=username]").val("username");
                this.dialog.$("input[name=groupList]").val("groupList");
                this.dialog.$("button[type=submit]").submit();
            });

            it("updates the model", function() {
                expect(this.dialog.model.get("name")).toBe("test3");
                expect(this.dialog.model.get("port")).toBe("8557");
                expect(this.dialog.model.get("host")).toBe("testhost3");
                expect(this.dialog.model.get("username")).toBe("username");
                expect(this.dialog.model.get("groupList")).toBe("groupList");
                expect(this.dialog.model.has("dbName")).toBeFalsy();
            });
        });

        context("with a gnip instance", function() {
            beforeEach(function() {
                this.dialog.model = new chorus.models.GnipInstance();
                this.dialog.render();
                this.dialog.$("input[name=name]").val("test3");
                this.dialog.$("input[name=streamUrl]").val("https://www.test.me");
                this.dialog.$("input[name=username]").val("username");
                this.dialog.$("textarea[name=description]").val("some description");
                this.dialog.$("input[name=password]").val("newpass");
                this.dialog.$("button[type=submit]").submit();
            });

            it("updates the model", function() {
                expect(this.dialog.model.get("name")).toBe("test3");
                expect(this.dialog.model.get("streamUrl")).toBe("https://www.test.me");
                expect(this.dialog.model.get("username")).toBe("username");
                expect(this.dialog.model.get("description")).toBe("some description");
                expect(this.dialog.model.get("password")).toBe("newpass");
            });
        });

        context("when save completes", function() {
            beforeEach(function() {
                this.dialog.$("button.submit").submit();
                spyOnEvent(this.instance, "change");
                this.dialog.model.trigger("saved");
            });

            it("displays toast message", function() {
                expect(chorus.toast).toHaveBeenCalled();
            });

            it("closes the dialog", function() {
                expect(this.dialog.closeModal).toHaveBeenCalled();
            });

            it("triggers change on the source model", function() {
                expect("change").toHaveBeenTriggeredOn(this.instance);
            });
        });

        function itRecoversFromError() {
            it("takes the button out of 'loading' mode", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeFalsy();
            });

            it("sets the button text back to 'Uploading'", function() {
                expect(this.dialog.$("button.submit").text()).toMatchTranslation("instances.edit_dialog.save");
            });
        }

        context("when the upload gives a server error", function() {
            beforeEach(function() {
                this.dialog.model.set({serverErrors: { fields: { a: { BLANK: {} } } }});
                this.dialog.model.trigger("saveFailed");
            });

            it("display the correct error", function() {
                expect(this.dialog.$(".errors").text()).toContain("A can't be blank");
            });

            itRecoversFromError();
        });

        context("when the validation fails", function() {
            beforeEach(function() {
                this.dialog.model.trigger("validationFailed");
            });

            itRecoversFromError();
        });
    });
});
