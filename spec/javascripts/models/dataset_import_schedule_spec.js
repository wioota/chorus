describe('chorus.models.DatasetImportSchedule', function() {
    beforeEach(function() {
        this.model = rspecFixtures.datasetImportScheduleSet().at(0);
        this.model.set({ workspaceId: "999", datasetId: "23456"});
    });

    it("has the correct URL", function () {
        expect(this.model.url()).toContain("/workspaces/999/datasets/23456/import_schedules");
    });


    xdescribe("#startTime, #endTime, #frequency", function() {
        context("when the import has the 'startDatetime' attribute (as required by the POST api)", function() {
            beforeEach(function() {
                this.model.set({
                    startDatetime: "2012-05-27T14:30:00Z",
                    endDate: "2012-08-28",
                    frequency: "MONTHLY"
                });
            });

            it("returns the import's scheduled start time, without the milliseconds", function() {
                expect(this.model.startTime().compareTo(Date.parseFromApi("2012-05-27T14:30:00Z"))).toBe(0);
            });

        });

        context("when the import has a 'scheduleInfo' attribute (as returned by the GET api)", function() {
            beforeEach(function() {
                this.model.unset("startDatetime");
                this.model.unset("endDate");
                this.model.set({
                    startDatetime: "2012-05-27T14:30:00Z",
                    endDate: "2012-08-28",
                    frequency: "MONTHLY"
                });
            });

            itReturnsTheCorrectTimes();
            it("returns the import's scheduled start time, without the milliseconds", function() {
                expect(this.model.startTime().compareTo(Date.parseFromApi("2012-05-27T14:30:00Z"))).toBe(0);
            });

        });

        context("when the import doesn't have a 'scheduleStartTime''", function() {
            beforeEach(function() {
                this.model.unset("startDatetime");
                this.model.unset("endDate");
                this.model.unset("frequency");
            });

            it("returns undefined for endTime and frequency", function() {
                expect(this.model.endTime()).toBeUndefined();
                expect(this.model.frequency()).toBeUndefined();
                expect(this.model.startTime()).toBeUndefined();
            });

        });

        it("demands that the start date is before the end date", function() {
            this.attrs = {
                isActive: true,
                scheduleStartTime: "y",
                scheduleEndTime: "x",
                toTable: "Foo",
                sampleCount: "23",
                truncate: "true",
                newTable: "false"
            };
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
        });

        function itReturnsTheCorrectTimes() {

            it("returns the import's end time", function() {
                expect(this.model.endTime().compareTo(Date.parse('2012-08-28'))).toBe(0);
            });
        }
    });

});