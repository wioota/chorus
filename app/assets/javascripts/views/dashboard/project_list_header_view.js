chorus.views.ProjectListHeader = chorus.views.Base.extend({
    constructorName: "ProjectListHeaderView",
    templateName: "project_list_content_header",
    additionalClass: 'list_header',

    events: {
        'click .menus > a': 'triggerCollectionFilter'
    },

    setup: function(params) {
        if(params.state === 'most_active') {
            this.mostActive = true;
            this.noFilter = true;
        }
        else {
            this.mostActive = false;
            if(params.state === 'all') {
                this.noFilter = true;
            }
            else {
                this.noFilter = false;
            }
        }
    },

    triggerCollectionFilter: function (e) {
        e && e.preventDefault();

        this.filterClass = e.target.classList[0];
        if(this.mostActive) {
            if(this.filterClass == 'members_only' || this.filterClass == 'all') {
                this.list.fillOutContent('', this.filterClass);
            }
        }
        else {
            if(this.filterClass == 'most_active') {
                this.list.fillOutContent('most_active', 'most_active');
            }
            else {
                this.mostActive = false;
                this.noFilter = this.filterClass === 'all';
                this.projectlist.triggerRender(this.filterClass === 'all');
                this.render();
            }
        }
    },

    additionalContext: function () {
        return {
            title: 'header.' + (this.mostActive ? 'most_active_projects' : (this.noFilter ? 'all_projects' : 'my_projects')),
            noFilter: this.noFilter,
            mostActive: this.mostActive
        };
    }
});
