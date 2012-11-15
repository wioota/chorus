describe("chorus.collections.WorkspaceDatasetSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.WorkspaceDatasetSet([], {workspaceId: 10000});
    });

    it("extends chorus.collections.LastFetchWins", function() {
        expect(this.collection).toBeA(chorus.collections.LastFetchWins);
    });

    describe("#url", function() {
        it("is correct", function() {
            expect(this.collection.url({per_page: 10, page: 1})).toMatchUrl("/workspaces/10000/datasets?per_page=10&page=1");
        });

        context("with filter type", function() {
            it("appends the filter type", function() {
                this.collection.attributes.type = "SOURCE_TABLE";
                expect(this.collection.url({per_page: 10, page: 1})).toContainQueryParams({type: "SOURCE_TABLE", per_page: "10", page: "1"});
            });
        });

        context("with name pattern", function() {
            beforeEach(function() {
                this.collection.attributes.namePattern = "Foo";
            });

            it("appends the name pattern", function() {
                expect(this.collection.url({per_page: 10, page: 1})).toContainQueryParams({
                    namePattern: "Foo",
                    per_page: "10",
                    page: "1"
                });
            });
        });

        context("with lots of url params", function() {
            it("correctly builds the url", function() {
                this.collection.attributes.type = "SOURCE_TABLE";
                this.collection.attributes.objectType = "TABLE";
                this.collection.attributes.namePattern = "Foo";
                this.collection.attributes.databaseName = "dbName";
                expect(this.collection.url({per_page: 10, page: 1})).toContainQueryParams({
                    type: "SOURCE_TABLE",
                    namePattern: "Foo",
                    databaseName: "dbName",
                    per_page: "10",
                    page: "1"
                });
            });
        });
    });

    describe("save", function() {
        it("includes the datasetId params", function() {
            this.collection.add(rspecFixtures.workspaceDataset.datasetTable({id: 1234, objectName: 'second'}));
            this.collection.add(rspecFixtures.workspaceDataset.datasetTable({id: 5678, objectName: 'first'}));
            this.collection.save();

            var bodyParams = decodeURIComponent(this.server.lastCreateFor(this.collection).requestBody).split("&");
            expect(bodyParams).toContain("dataset_ids[]=5678");
            expect(bodyParams).toContain("dataset_ids[]=1234");
        });
    });

    describe("sorting", function() {
        context("without a sorting override", function() {
            beforeEach(function() {
                this.collection.add(rspecFixtures.workspaceDataset.datasetTable({objectName: 'zTable'}));
                this.collection.add(rspecFixtures.workspaceDataset.datasetTable({objectName: 'aTable'}));
            });

            it("sorts by objectName", function() {
                expect(this.collection.at(0).get("objectName")).toBe("aTable");
                expect(this.collection.at(1).get("objectName")).toBe("zTable");
            });
        });

        context("with a sorting override", function() {
            beforeEach(function() {
                this.collection = new chorus.collections.WorkspaceDatasetSet([], {workspaceId: 10000, unsorted: true});
                this.collection.add(rspecFixtures.workspaceDataset.datasetTable({objectName: 'zTable'}));
                this.collection.add(rspecFixtures.workspaceDataset.datasetTable({objectName: 'aTable'}));
            });

            it("does not sort", function() {
                expect(this.collection.at(0).get("objectName")).toBe("zTable");
                expect(this.collection.at(1).get("objectName")).toBe("aTable");
            });
        });
    });

    describe("#hasFilter", function() {
        describe("when there is a name filter", function() {
            beforeEach(function() {
                this.collection.attributes.namePattern = "foo";
            });

            it("should be true", function() {
                expect(this.collection.hasFilter()).toBeTruthy();
            });
        });

        describe("when there is a type filter", function() {
            beforeEach(function() {
                this.collection.attributes.type = "foo";
            });

            it("should be true", function() {
                expect(this.collection.hasFilter()).toBeTruthy();
            });
        });

        describe("when there is not name or type filter", function() {
            it("should be false", function() {
                expect(this.collection.hasFilter()).toBeFalsy();
            });
        });
    });
});
