describe('chorus.models.DataSource', function() {
    beforeEach(function() {
            this.model = new chorus.models.DataSource({id: 1});
        }
    );

    describe('#providerIconUrl', function() {
        it('has the right icon', function() {
            var gpdbInstance = new chorus.models.DataSource({entityType: 'gpdb_instance'});
            expect(gpdbInstance.providerIconUrl()).toEqual('/images/instances/icon_gpdb_instance.png');
            var oracleInstance = new chorus.models.DataSource({entityType: 'oracle_instance'});
            expect(oracleInstance.providerIconUrl()).toEqual('/images/instances/icon_oracle_instance.png');
        });
    });

    describe('#showUrl', function(){
        it('has the right url', function(){
            expect(this.model.showUrl()).toEqual('#/instances/' + this.model.id + '/databases');
        });
    });
});
