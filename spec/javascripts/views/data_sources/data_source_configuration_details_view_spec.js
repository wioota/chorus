describe("chorus.views.DataSourceConfigurationDetails", function() {
    beforeEach(function() {
        this.dataSource = rspecFixtures.hdfsDataSource({
            jobTrackerHost: 'foobar',
            jobTrackerPort: '1234'
        });
        this.view = new chorus.views.DataSourceConfigurationDetails({model: this.dataSource});
    });

    it("should display the job tracker host and port for a hdfs (if they exist)", function() {
        this.view.render();
        expect(this.view.$(".job_tracker_host")).toContainText('foobar');
        expect(this.view.$(".job_tracker_port")).toContainText('1234');
    });

    it("should not display the job tracker host and port for a hdfs (if they don't exist)", function() {
        this.dataSource.set('jobTrackerHost', null);
        this.dataSource.set('jobTrackerPort', null);
        this.view.render();
        expect(this.view.$(".job_tracker_host")).not.toExist();
        expect(this.view.$(".job_tracker_port")).not.toExist();
    });
});