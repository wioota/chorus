describe("chorus.models.HdfsDataSource", function() {
    beforeEach(function() {
        this.model = rspecFixtures.hdfsDataSource({id : 123, username: "hadoop", groupList: "hadoop"});
        this.attrs = {};
    });

    it("has the right url", function() {
        expect(this.model.url()).toBe("/hdfs_data_sources/123");
    });

    it("is shared", function() {
        expect(this.model.isShared()).toBeTruthy();
    });

    it("has the correct entityType", function() {
        expect(this.model.entityType).toBe("hdfs_data_source");
    });

    it('links to the root directory of the hadoop data source', function() {
        expect(this.model.showUrl()).toBe("#/hdfs_data_sources/" + this.model.get('id') + "/browse/");
    });

    it("returns true for isHadoop", function() {
        expect(this.model.isHadoop()).toBeTruthy();
    });

    _.each(["name", "host", "username", "groupList", "port"], function(attr) {
        it("requires " + attr, function() {
            this.attrs[attr] = "";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
            expect(this.model.errors[attr]).toBeTruthy();
        });
    });

    it("requires name with valid length", function() {
        this.attrs.name = "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest";
        expect(this.model.performValidation(this.attrs)).toBeFalsy();
        expect(this.model.errors.name).toMatchTranslation("validation.required_pattern", {fieldName: "name"});
    });

    describe("#sharedAccountDetails", function() {
        it('returns the account name of the user who owns the data source and shared it', function() {
            var sharedAccountDetails = this.model.get("username") + ", " + this.model.get("groupList");
            expect(this.model.sharedAccountDetails()).toBe(sharedAccountDetails);
        });
    });
});