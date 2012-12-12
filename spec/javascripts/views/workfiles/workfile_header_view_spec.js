describe("chorus.views.WorkfileHeader", function() {
    beforeEach(function() {
        this.view = new chorus.views.WorkfileHeader();
        this.model = rspecFixtures.workfile.sql({id: this.workfileId, workspace: {id: this.workspaceId}});
        this.view.model = this.model;
        this.view.render();
    });

    describe("editing tags", function() {
        context("when there are no tags on a workfile", function() {
            xit('shows the add tags link', function() {
                expect(this.view.$('a')).toContainTranslation('tags.add_tags');
            });

            xit("opens a text box when add tags is clicked", function() {
                this.view.$('a.edit_tags').click();
                expect(this.view.$('textarea')).toExist();
                expect(this.view).not.toHaveText(t('tags.add_tags'));
                expect(this.view.$('a.save_tags')).toExist();
            });

            describe("when the done button is clicked", function() {
                beforeEach(function() {
                    this.view.$('input[type=hidden]').val('["alpha", "beta", "gamma"]');
                    this.view.$('a.save_tags').click();
                });

                xit("closes the text box", function() {
                    expect(this.view.$('textarea')).not.toExist();
                });

                it('saves the tags', function() {
                    var tagSave = this.server.lastCreate();
                    var requestBody = decodeURIComponent(tagSave.requestBody);
                    expect(tagSave.url).toBe('/taggings');
                    expect(requestBody).toContain("entity_id="+this.model.id);
                    expect(requestBody).toContain("entity_type=workfile");
                    expect(requestBody).toContain("tag_names[]=alpha");
                    expect(requestBody).toContain("tag_names[]=beta");
                    expect(requestBody).toContain("tag_names[]=gamma");
                });

                xit("displays the new tags", function() {
//                    expect(this.view.$('a')).toContainTranslation('tags.edit_tags');
                });
            });
        })
    });
});
