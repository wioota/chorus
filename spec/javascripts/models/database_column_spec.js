describe("chorus.models.DatabaseColumn", function() {
    beforeEach(function() {
        this.model = new chorus.models.DatabaseColumn({name: "Col", type: 'varbit'});
    });

    describe("#initialize", function() {
        context("when there is tabularData", function() {
            beforeEach(function() {
                this.model.initialize();
            });

            it("does not blow up", function() {
                expect(this.model.get('name')).toBe('Col');
            });
        });

        context("when there is tabularData", function() {
            beforeEach(function() {
                this.tabularData = fixtures.datasetSandboxTable({objectName: 'taaab', schemaName: 'partyman'});
                this.model.tabularData = this.tabularData;
                this.model.initialize();
            });

            it("sets instanceId, databaseName, schemaName, parentName, and parentType", function() {
                expect(this.model.get("instanceId")).toBe(this.model.tabularData.get('instance').id);
                expect(this.model.get("databaseName")).toBe(this.model.tabularData.get('databaseName'));
                expect(this.model.get("schemaName")).toBe(this.model.tabularData.get('schemaName'));
                expect(this.model.get("parentName")).toBe(this.model.tabularData.get('objectName'));
                expect(this.model.get("parentType")).toBe(this.model.tabularData.metaType());
            });

            describe("#url", function() {
                it("is correct", function() {
                    var attr = this.model.attributes;
                    expect(this.model.url({ rows: 10, page: 1})).toMatchUrl("/edc/data/"+attr.instanceId+"/database/"+attr.databaseName+"/schema/"+attr.schemaName+"/"+attr.parentType+"/"+attr.parentName+"/column?filter="+attr.name+"&type=meta");
                });
            });

            describe("#toText", function() {
                context("with lowercase names", function() {
                    beforeEach(function() {
                        this.model.set({name: "col"})
                    })
                    it("formats the string to put into the sql editor", function() {
                        expect(this.model.toText()).toBe('partyman.taaab.col');
                    })
                })
                context("with uppercase names", function() {
                    beforeEach(function() {
                        this.model.set({name: "Col", schemaName: "PartyMAN", parentName: "TAAAB"});
                    })
                    it("puts quotes around the uppercase names", function() {
                        expect(this.model.toText()).toBe('"PartyMAN"."TAAAB"."Col"');
                    })
                })
            })

            describe("#humanType", function() {
                var expectedTypeMap = {
                    "WHOLE_NUMBER" : "numeric",
                    "REAL_NUMBER" : "numeric",
                    "STRING" : "string",
                    "LONG_STRING" : "string",
                    "BINARY" : "binary",
                    "BOOLEAN" : "boolean",
                    "DATE" : "date",
                    "TIME" : "time",
                    "DATETIME" : "date_time",
                    "OTHER" : "other"
                }

                _.each(expectedTypeMap, function(str, type) {
                    it("works for " + type, function() {
                        expect(new chorus.models.DatabaseColumn({ typeCategory : type }).humanType()).toBe(str)
                    });
                })
            })
        });
    });
});
