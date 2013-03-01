describe("chorus.models.DatasetImport", function() {
    beforeEach(function() {
        this.model = rspecFixtures.datasetImportSet().at(0);
        this.model.set({
            datasetId: '102',
            workspaceId: '1'
        });
    });

    describe('url', function() {
        it('saves to the workspace/:id/dataset/:dataset_id/imports', function() {
            expect(this.model.url()).toHaveUrlPath('/workspaces/1/imports');
        });
    });

    describe("#isInProgress", function() {
        it("returns true when the import has a startedStamp but no completedStamp", function() {
            this.model.set({ success: true, startedStamp: "something", completedStamp: null });
            expect(this.model.isInProgress()).toBeTruthy();
        });

        it("returns false if the import has a completedStamp", function() {
            this.model.set({ success: true, completedStamp: "Yesterday" });
            expect(this.model.isInProgress()).toBeFalsy();
        });

        it("returns false if the import has no time info", function() {
            this.model.set({ success: null, startedStamp: null, completedStamp: null });
            expect(this.model.isInProgress()).toBeFalsy();
        });
    });

    describe("#beforeSave", function() {
        context("when the model has a 'sampleCount'", function() {
            beforeEach(function() {
                this.model.set({
                    newTable: 'true',
                    truncate: 'true',
                    useLimitRows: true,
                    sampleCount: 477
                });
            });

            it("sets the 'sampleMethod' parameter, as required by the API", function() {
                this.model.save();
                var params = this.server.lastUpdate().params();
                expect(params["dataset_import[sample_count]"]).toBe('477');
            });
        });
    });

    describe("validations", function() {
        context("when creating a new table", function() {
            beforeEach(function() {
                this.attrs = {
                    toTable: "Foo",
                    sampleCount: "23",
                    truncate: "true",
                    newTable: "true"
                };
            });

            _.each(["toTable", "truncate", "newTable"], function(attr) {
                it("should require " + attr, function() {
                    this.attrs[attr] = "";
                    expect(this.model.performValidation(this.attrs)).toBeFalsy();
                });
            });

            context("with a conforming toTable name", function() {
                it("validates", function() {
                    expect(this.model.performValidation(this.attrs)).toBeTruthy();
                });
            });

            context("with a non-conforming toTable name", function() {
                beforeEach(function() {
                    this.attrs.toTable = "__foo";
                });

                it("fails validations", function() {
                    expect(this.model.performValidation(this.attrs)).toBeFalsy();
                });
            });

            context("when useLimitRows is enabled", function() {
                beforeEach(function() {
                    this.attrs.useLimitRows = true;
                });

                it("should only allow digits for the row limit", function() {
                    this.attrs.sampleCount = "a3v4s5";
                    expect(this.model.performValidation(this.attrs)).toBeFalsy();
                });
            });

            context("when useLimitRows is not enabled", function() {
                beforeEach(function() {
                    this.attrs.useLimitRows = false;
                });

                it("should not validate the sampleCount field", function() {
                    this.attrs.sampleCount = "";
                    expect(this.model.performValidation(this.attrs)).toBeTruthy();
                });
            });
        });

        context("when importing into an existing table", function() {
            beforeEach(function() {
                this.attrs = {
                    toTable: "Foo",
                    sampleCount: "23",
                    truncate: "true",
                    newTable: "false"
                };
            });

            context("with a conforming toTable name", function() {
                it("validates", function() {
                    expect(this.model.performValidation(this.attrs)).toBeTruthy();
                });
            });

            context("with a toTable name that does not conform to the new table regex constraints", function() {
                beforeEach(function() {
                    this.attrs.toTable = "__foo";
                });

                it("validates", function() {
                    expect(this.model.performValidation(this.attrs)).toBeTruthy();
                });
            });
        });
    });

    describe("#source", function() {
        it("sets the model correctly", function() {
            this.model.set({workspaceId: 123, sourceDatasetId: 567, sourceDatasetName: 'source'});
            expect(this.model.source().url()).toContain("/workspaces/123/datasets/567");
            expect(this.model.source().name()).toBe('source');
        });
    });
});
