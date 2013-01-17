describe("chorus.models.AlpineWorkfile", function () {
    describe("iconUrl", function () {
        var workfile;
        beforeEach(function() {
            workfile = new chorus.models.AlpineWorkfile();
        });

        it("returns the afm icon", function () {
            expect(workfile.iconUrl()).toMatch(/afm\.png/);
        });

        it("returns the correct size", function () {
            expect(workfile.iconUrl({size: 'icon'})).toMatch(/icon.*afm\.png/);
        });
    });
});