chorus.views.BreadcrumbsView = chorus.views.Base.extend({
    constructorName: "BreadcrumbsView",
    templateName:"breadcrumbs",

    additionalContext: function () {
        var crumbs = this.options.breadcrumbs;

        return {
            breadcrumbs: (_.isFunction(crumbs) ? crumbs() : crumbs)
        };
    },

    postRender: function() {
        var $crumb = this.$(".breadcrumb");
        _.each(this.context().breadcrumbs, function(breadcrumb, index){
            if (breadcrumb.data) {
                $crumb.eq(index).find('a').data(breadcrumb.data);
            }
        });
    }
});