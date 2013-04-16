chorus.views.MultipleSelectionSidebarMenu = chorus.views.Base.extend({
    constructorName: "MultiSelectionSidebarMenu",
    templateName: "multiple_selection_sidebar_menu",

    events: {
        "click .deselect_all": 'deselectAll'
    },

    setup: function() {
        this.actions = this.options.actions;
        this.selectEvent = this.options.selectEvent;
        this.selectedModels = new chorus.collections.Base();
        this.events = _.extend({}, this.events, this.options.actionEvents);
        this.subscribePageEvent(this.selectEvent, this.modelSelected);
    },

    render: function() {
        this._super("render", arguments);
    },

    modelSelected: function(selectedModels) {
        this.selectedModels = selectedModels;
        this.render();
    },

    showOrHideMultipleSelectionSection: function() {
        if(this.selectedModels.length > 0) {
            this.$el.removeClass('hidden');
        } else {
            this.$el.addClass("hidden");
        }
    },

    deselectAll: function(e) {
        e.preventDefault();
        chorus.PageEvents.trigger("selectNone");
    },

    additionalContext: function() {
        return {
            selectedModels: this.selectedModels,
            actions: this.actions.map(function(action) {
               return Handlebars.compile(action)();
            })
        };
    },

    postRender: function() {
        this.showOrHideMultipleSelectionSection();
        this._super("postRender");
    }
});
