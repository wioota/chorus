chorus.views.MultipleSelectionSidebar = chorus.views.Base.extend({
    constructorName: "MultiSelectionSidebarView",
    templateName: "multiple_selection_sidebar",

    events: {
        "click .deselect_all": 'deselectAll'
    },

    setup: function() {
        this.actions = this.options.actions;
        this.selectEvent = this.options.selectEvent;
        this.selectedModels = new chorus.collections.Base();
        this.subscriptions.push(chorus.PageEvents.subscribe(this.selectEvent, this.modelSelected, this));
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
        chorus.PageEvents.broadcast("selectNone");
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
