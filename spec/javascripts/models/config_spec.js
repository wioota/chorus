describe("chorus.models.Config", function() {
    var config;
    beforeEach(function() {
        config = rspecFixtures.config();
    });

    it("has a valid url", function() {
        expect(config.url()).toBe("/config/");
    });

    describe("#isExternalAuth", function() {
        it("returns externalAuthEnabled", function() {
            expect(config.isExternalAuth()).toBeTruthy();
        });
    });

    describe("#fileSizeMbWorkfiles", function() {
        it("returns the workfiles size limit", function() {
            expect(config.fileSizeMbWorkfiles()).toBe(10);
        });
    });

    describe("#fileSizeMbCsvImports", function() {
        it("returns the csv import size limit", function() {
            expect(config.fileSizeMbCsvImports()).toBe(1);
        });
    });
});
