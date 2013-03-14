describe('chorus.handlebarsHelpers.time', function() {
    describe("displayTimestamp", function () {
        it("renders the timestamp without milliseconds", function () {
            expect(Handlebars.helpers.displayTimestamp("2011-1-23T15:42:02Z")).toBe("January 23");
        });

        it("tolerates bogus timestamps", function () {
            expect(Handlebars.helpers.displayTimestamp("invalid")).toBe("WHENEVER");
        });

        it("tolerates undefined", function () {
            expect(Handlebars.helpers.displayTimestamp()).toBe("WHENEVER");
        });
    });

    describe("relativeTimestamp", function () {
        it("renders the relative timestamp", function () {
            var tm = Date.formatForApi((50).hours().ago());
            expect(Handlebars.helpers.relativeTimestamp(tm)).toBe("2 days ago");
        });

        it("tolerates bogus timestamps", function () {
            expect(Handlebars.helpers.relativeTimestamp("invalid")).toBe("WHENEVER");
        });

        it("tolerates undefined", function () {
            expect(Handlebars.helpers.relativeTimestamp()).toBe("WHENEVER");
        });
    });
});
