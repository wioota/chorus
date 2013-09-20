chorus.views.ProjectListHeader = chorus.views.Base.extend({
    constructorName: "ProjectListHeaderView",
    templateName: "project_list_content_header",
    additionalClass: 'list_header',
    filterClass: 'all',

    events: {
        'click .menus > a': 'triggerCollectionFilter'
    },

    triggerCollectionFilter: function (e) {
        e && e.preventDefault();

        this.filterClass = e.target.classList[0];
        this.collection.trigger('filter:'+ this.filterClass);
        this.render();
    },

    additionalContext: function () {
        return {
            title: t('header.current_projects'),
            noFilter: this.filterClass === 'all'
        };
    }
});
