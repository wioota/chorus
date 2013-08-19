describe('chorus.handlebarsHelpers.time', function() {
    describe("displayAbbreviatedTimestamp", function () {
        it("renders the timestamp without milliseconds", function () {
            expect(Handlebars.helpers.displayAbbreviatedTimestamp("2011-1-23T15:42:02Z")).toBe("January 23");
        });

        it("tolerates bogus timestamps", function () {
            expect(Handlebars.helpers.displayAbbreviatedTimestamp("invalid")).toBe("");
        });

        it("tolerates undefined", function () {
            expect(Handlebars.helpers.displayAbbreviatedTimestamp()).toBe("");
        });
    });

    describe("relativeTimestamp", function () {
        it("renders the relative timestamp", function () {
            var tm = Date.formatForApi((50).hours().ago());
            expect(Handlebars.helpers.relativeTimestamp(tm)).toBe("2 days ago");
        });

        it("tolerates bogus timestamps", function () {
            expect(Handlebars.helpers.relativeTimestamp("invalid")).toBe("");
        });

        it("tolerates undefined", function () {
            expect(Handlebars.helpers.relativeTimestamp()).toBe("");
        });
    });

    describe("dispalyTimestamp", function () {
        it("renders the timestamp without milliseconds", function () {
            expect(Handlebars.helpers.displayTimestamp("2011-01-23T15:42:02Z")).toBe("January 23rd 2011, 7:42 am");
        });

        it("tolerates bogus timestamps", function () {
            expect(Handlebars.helpers.displayTimestamp("invalid")).toBe("");
        });

        it("tolerates undefined", function () {
            expect(Handlebars.helpers.displayTimestamp()).toBe("");
        });
    });

    describe("displayDuration", function () {
        it("renders the duration", function () {
            expect(Handlebars.helpers.displayDuration("2011-01-23T15:42:02Z", "2011-01-23T14:40:00Z")).toBe('01:02:02');
        });

        it("tolerates bogus timestamps", function () {
            expect(Handlebars.helpers.displayDuration("invalid", "2011-01-23T15:42:02Z")).toBe("");
        });

        it("tolerates undefined", function () {
            expect(Handlebars.helpers.displayDuration()).toBe("");
        });
    });
});
