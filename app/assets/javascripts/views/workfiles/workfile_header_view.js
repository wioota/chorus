chorus.views.WorkfileHeader = chorus.views.Base.extend({
    templateName: "workfile_header",
    constructorName: "WorkfileHeaderView",
    additionalClass: 'show_page_header',

    subviews: {
        '.tag_box': 'tagBox'
    },

    setup: function() {
       this.tagBox = new chorus.views.TagBox({model: this.model});
    },

    additionalContext: function() {
        return {
            iconUrl: this.model.iconUrl()
        };
    }
});
