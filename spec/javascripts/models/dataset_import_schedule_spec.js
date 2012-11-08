describe('chorus.models.DatasetImportSchedule', function () {
    beforeEach(function () {
        this.model = rspecFixtures.datasetImportScheduleSet().at(0);
        this.model.set({ workspaceId: "999", datasetId: "23456"});
    });

    it("has the correct URL", function () {
        expect(this.model.url()).toContain("/workspaces/999/datasets/23456/import_schedules");
    });

    describe("validations", function () {
        beforeEach(function () {
            this.attrs = {
                newTable: "true",
                scheduleStartTime: "10-11-12",
                scheduleEndTime: "12-12-12",
                toTable: "tableName123",
                truncate: "false",
                useLimitRows: true,
                sampleCount: 500
            };
            expect(this.model.performValidation(this.attrs)).toBeTruthy();
        });

        it("rejects new table names which do not match the ChorusIdentifier64 rules", function () {
            this.attrs.toTable = "!!!";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
        });

        it("is cool with existing table names", function () {
            this.attrs.newTable = "false";
            this.attrs.toTable = "!!!";
            expect(this.model.performValidation(this.attrs)).toBeTruthy();
        });

        it("requires truncate to be a string of type boolean", function () {
            this.attrs.truncate = "maybe";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
        });

        it("requires new table to be a string of type boolean", function () {
            this.attrs.newTable = "sometimes";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
        });

        it("requires sampleCount to be an integer if using limit rows", function () {
            this.attrs.useLimitRows = "true";
            this.attrs.sampleCount = "orange";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
        });

        it("doesn't need sampleCount if not using limit rows", function () {
            this.attrs.useLimitRows = false;
            this.attrs.sampleCount = undefined;
            expect(this.model.performValidation(this.attrs)).toBeTruthy();
        });

        it("demands that the start date is before the end date", function () {
            this.attrs.scheduleStartTime = "12-11-10";
            this.attrs.scheduleEndTime = "11-10-09";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
        });
    });

    describe("#startTime, #endTime, #frequency", function () {
        context("when the import has the 'startDatetime' attribute (as required by the POST api)", function () {
            beforeEach(function () {
                this.model.set({
                    startDatetime: "2012-05-27T14:30:00Z",
                    endDate: "2012-08-28",
                    frequency: "MONTHLY"
                });
            });

            it("returns the import's scheduled start time, without the milliseconds", function () {
                expect(this.model.startTime().compareTo(Date.parseFromApi("2012-05-27T14:30:00Z"))).toBe(0);
            });

        });

        context("when the import has a 'scheduleInfo' attribute (as returned by the GET api)", function () {
            beforeEach(function () {
                this.model.unset("startDatetime");
                this.model.unset("endDate");
                this.model.set({
                    startDatetime: "2012-05-27T14:30:00Z",
                    endDate: "2012-08-28",
                    frequency: "MONTHLY"
                });
            });

            itReturnsTheCorrectTimes();
            it("returns the import's scheduled start time, without the milliseconds", function () {
                expect(this.model.startTime().compareTo(Date.parseFromApi("2012-05-27T14:30:00Z"))).toBe(0);
            });

        });

        context("when the import doesn't have a 'scheduleStartTime''", function () {
            beforeEach(function () {
                this.model.unset("startDatetime");
                this.model.unset("endDate");
                this.model.unset("frequency");
            });

            it("returns undefined for endTime and frequency", function () {
                expect(this.model.endTime()).toBeUndefined();
                expect(this.model.frequency()).toBeUndefined();
            });

        });


        function itReturnsTheCorrectTimes() {

            it("returns the import's end time", function () {
                expect(this.model.endTime().compareTo(Date.parse('2012-08-28'))).toBe(0);
            });
        }
    });

});