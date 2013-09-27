chorus.views.ProjectListHeader = chorus.views.Base.extend({
    constructorName: "ProjectListHeaderView",
    templateName: "project_list_content_header",
    additionalClass: 'list_header',
    noFilter: false,

    events: {
        'click .menus > a': 'triggerCollectionFilter'
    },

    triggerCollectionFilter: function (e) {
        e && e.preventDefault();

        this.filterClass = e.target.classList[0];
        this.noFilter = this.filterClass === 'all';
        this.collection.trigger('filter:'+ this.filterClass);
        this.render();
    },

    additionalContext: function () {
        return {
            title: 'header.' + (this.noFilter ? 'all_projects' : 'my_projects'),
            noFilter: this.noFilter
        };
    }
});
