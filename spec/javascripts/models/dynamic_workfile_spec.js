describe("chorus.models.DynamicWorkfile", function() {
    it("should return an alpine workfile when the type is alpine", function() {
        var model = new chorus.models.DynamicWorkfile(rspecFixtures.workfile.alpine().attributes);
        expect(model).toBeA(chorus.models.AlpineWorkfile);
    });

    it("should return a workfile otherwise", function() {
        var model = new chorus.models.DynamicWorkfile({});
        expect(model).toBeA(chorus.models.Workfile);
    });
});