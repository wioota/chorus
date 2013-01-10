chorus.views.MultipleSelectionSidebar = chorus.views.Base.extend({
    constructorName: "MultiSelectionSidebarView",
    templateName: "multiple_selection_sidebar",

    events: {
        "click .deselect_all": 'deselectAll'
    },

    setup: function() {
        this.actions = this.options.actions;
        this.select_event = this.options.select_event;
        this.selectedModels = new chorus.collections.Base();
        this.subscriptions.push(chorus.PageEvents.subscribe(this.select_event, this.modelSelected, this));
    },

    render: function() {
//        if (!this.disabled) {
            this._super("render", arguments);
//        }
    },

    modelSelected: function(selectedModels) {
        this.selectedModels = selectedModels;
        this.render();
    },

    showOrHideMultipleSelectionSection: function() {
        if(this.selectedModels && this.selectedModels.length < 2) {
            this.$el.addClass("hidden");
        } else {
            this.$el.removeClass('hidden');
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
