describe("chorus.collections.HdfsEntrySet", function() {
    context('when the collection has path and data source set', function() {
        beforeEach(function() {
            this.hdfsEntrySet = new chorus.collections.HdfsEntrySet([rspecFixtures.hdfsFile()], {
                path: '/data/somewhere',
                hdfsDataSource: {id: 222},
                id: 11
            });
        });

        describe("add", function() {
            it("sets the path and data source on the added entries", function() {
                expect(this.hdfsEntrySet.at(0).get('hdfsDataSource')).toBe(this.hdfsEntrySet.attributes.hdfsDataSource);
            });
        });

        describe("hdfsEntry", function() {
            it("returns a HdfsEntry representing the location of the Set", function() {
                var model = this.hdfsEntrySet.hdfsEntry();
                expect(model).toBeA(chorus.models.HdfsEntry);
                expect(model.id).toBe(11);
                expect(model.get('hdfsDataSource')).toEqual({id: 222});
                expect(model.get('isDir')).toBeTruthy();
            });
        });
    });

    context("when the collection does not have path and instanceId set", function() {
        beforeEach(function() {
            this.hdfsEntrySet = new chorus.collections.HdfsEntrySet([], {
                path: null,
                hdfsDataSource: null
            });
        });

        describe("add", function() {
            it("keeps the path and data source already set on the entry", function() {
                var entry = rspecFixtures.hdfsFile({path: '/data/foo', hdfsDataSource: {id: '10000'}});
                this.hdfsEntrySet.add(entry);
                expect(this.hdfsEntrySet.at(0).get('path')).toBe('/data/foo');
                expect(this.hdfsEntrySet.at(0).get('hdfsDataSource').id).toBe('10000');
            });
        });
    });
});
