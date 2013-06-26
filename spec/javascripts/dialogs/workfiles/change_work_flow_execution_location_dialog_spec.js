describe("chorus.dialogs.ChangeWorkFlowExecutionLocation", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workfile.alpine();
        this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
        this.dialog.render();
    });

    describe("#render", function () {
        it("has the right title", function () {
            expect(this.dialog.$(".dialog_header h1")).toContainTranslation("work_flows.change_execution_location.title");
        });

        it("has the right label text", function(){
            expect(this.dialog.$el).toContainTranslation("work_flows.new_dialog.info");
        });

        it("has a Save Search Path button", function () {
            expect(this.dialog.$("button.submit").text().trim()).toMatchTranslation("work_flows.change_execution_location.save");
        });

        it("has a Cancel button", function () {
            expect(this.dialog.$("button.cancel").text().trim()).toMatchTranslation("actions.cancel");
        });
    });

    context("a gpdb database", function() {
        beforeEach(function() {
            this.executionLocation = backboneFixtures.database({id: 321});
            this.model.set('executionLocation', this.executionLocation.attributes);
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        context("pre-populating", function() {
            it("passes the database and the gpdb data source to the picker", function() {
                expect(this.dialog.executionLocationPicker.options.database.attributes).toEqual(this.executionLocation.attributes);
                expect(this.dialog.executionLocationPicker.options.dataSource.attributes).toEqual(this.executionLocation.dataSource().attributes);
            });
        });

        context("saving", function() {
            beforeEach(function() {
                this.model.set("hdfs_data_source_id", "not_empty");
                spyOn(this.model, "save").andCallThrough();
                spyOn(this.dialog.executionLocationPicker, "ready").andReturn(true);
                spyOn(this.dialog, "closeModal");
                this.dialog.$("button.submit").click();
            });

            it("puts the button in 'loading' mode", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit")).toContainTranslation("actions.saving");
            });

            it("saves the model", function(){
                expect(this.server.lastUpdate().params()["workfile[database_id]"]).toEqual(this.executionLocation.id.toString());
                expect(this.server.lastUpdate().params()["workfile[hdfs_data_source_id]"]).toBeUndefined();
            });

            context("when save succeeds", function(){
                beforeEach(function() {
                    this.server.completeUpdateFor(this.model, _.extend(this.model.attributes, {executionLocation: this.executionLocation.attributes}));
                });

                it("dismisses the dialog", function(){
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });
            });

            context('when the save fails', function(){
                beforeEach(function() {
                    spyOn(this.dialog, "showErrors");
                    this.server.lastUpdateFor(this.model).failForbidden({message: "Forbidden"});
                });

                it("shows an error message", function() {
                    expect(this.dialog.showErrors).toHaveBeenCalledWith(this.model);
                });

                it("doesn't close the dialog box", function () {
                    this.dialog.model.trigger("savedFailed");
                    expect(this.dialog.closeModal).not.toHaveBeenCalled();
                });
            });
        });
    });

    context("an hdfs data source", function() {
        beforeEach(function() {
            this.executionLocation = backboneFixtures.hdfsDataSource({id: 123});
            this.model.set('executionLocation', this.executionLocation.attributes);
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        context("pre-populating", function() {

            it("only passes the data source to the picker", function() {
                expect(this.dialog.executionLocationPicker.options.database).toBeUndefined();
                expect(this.dialog.executionLocationPicker.options.dataSource.attributes).toEqual(this.executionLocation.attributes);
            });
        });

        context("saving", function() {
            beforeEach(function() {
                this.model.set("database_id", "NOT_EMPTY");
                spyOn(this.model, "save").andCallThrough();
                spyOn(this.dialog.executionLocationPicker, "ready").andReturn(true);
                spyOn(this.dialog, "closeModal");
                this.dialog.$("button.submit").click();
            });

            it("puts the button in 'loading' mode", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit")).toContainTranslation("actions.saving");
            });

            it("saves the model", function(){
                expect(this.server.lastUpdate().params()["workfile[hdfs_data_source_id]"]).toEqual(this.executionLocation.id.toString());
                expect(this.server.lastUpdate().params()["workfile[database_id]"]).toBeUndefined();
            });

            context("when save succeeds", function(){
                beforeEach(function() {
                    this.server.completeUpdateFor(this.model, _.extend(this.model.attributes, {executionLocation: this.executionLocation.attributes}));
                });

                it("dismisses the dialog", function(){
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });
            });

            context('when the save fails', function(){
                beforeEach(function() {
                    spyOn(this.dialog, "showErrors");
                    this.server.lastUpdateFor(this.model).failForbidden({message: "Forbidden"});
                });

                it("shows an error message", function() {
                    expect(this.dialog.showErrors).toHaveBeenCalledWith(this.model);
                });

                it("doesn't close the dialog box", function () {
                    this.dialog.model.trigger("savedFailed");
                    expect(this.dialog.closeModal).not.toHaveBeenCalled();
                });
            });
        });
    });

    context("when the picker is not ready", function () {
        beforeEach(function () {
            spyOn(this.dialog.executionLocationPicker, "ready").andReturn(false);
            this.dialog.executionLocationPicker.trigger("change");
        });

        it("disables the save button", function () {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });
    });

    context("when the picker is ready", function () {
        beforeEach(function () {
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
            spyOn(this.dialog.executionLocationPicker, "ready").andReturn(true);
            this.dialog.executionLocationPicker.trigger("change");
        });

        it("enables the save button", function () {
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });
    });

    context("when the picker triggers an error", function() {
        beforeEach(function() {
            var modelWithError = backboneFixtures.database();
            modelWithError.serverErrors = { fields: { a: { BLANK: {} } } };
            this.dialog.executionLocationPicker.trigger("error", modelWithError);
        });

        it("shows the error", function() {
            expect(this.dialog.$('.errors')).toContainText("A can't be blank");
        });

        context("and then the picker triggers clearErrors", function(){
            it("clears the errors", function() {
                this.dialog.executionLocationPicker.trigger("clearErrors");
                expect(this.dialog.$('.errors')).toBeEmpty();
            });
        });
    });
});