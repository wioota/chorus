describe("chorus.utilities.CsvWriter", function() {
    beforeEach(function() {
        this.options = {};
    });

    context("data has both column names and data", function() {
        beforeEach(function() {
            var columnNames = ["col1", "col2", "col3"];
            var rows = [
                {col1: "row 11", col2: "row 12", col3: "row 13"},
                {col1: "row 21", col2: "row 22", col3: "row 23"}];
            this.csvWriter = new chorus.utilities.CsvWriter(columnNames, rows, this.options);
        });

        it("writes both column name and data", function() {
            expect(this.csvWriter.toCsv()).toBe('"col1","col2","col3"\n"row 11","row 12","row 13"\n"row 21","row 22","row 23"\n');
        });
    });
});
