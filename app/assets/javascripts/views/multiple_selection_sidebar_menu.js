chorus.views.MultipleSelectionSidebarMenu = chorus.views.Base.include(
    chorus.Mixins.ActionPanel
).extend({
    constructorName: "MultiSelectionSidebarMenu",
    templateName: "multiple_selection_sidebar_menu",

    setup: function(options) {
        this.selectEvent    = options.selectEvent;
        this.selectedModels = new chorus.collections.Base();
        this.subscribePageEvent(this.selectEvent, this.modelSelected);
    },

    render: function() {
        this._super("render", arguments);
    },

    repopulateActions: function (selectedModels) {
        var providerIsAFunction = (this.options.actionProvider instanceof Function);
        this.actions = providerIsAFunction ? this.options.actionProvider(selectedModels) : this.options.actionProvider;

        var events = this.eventBindings(this.actions, { "click .deselect_all": 'deselectAll' });
        this.delegateEvents(events);

        this.render();
    },

    modelSelected: function(selectedModels) {
        this.selectedModels = selectedModels;
        this.repopulateActions(this.selectedModels);
    },

    showOrHideMultipleSelectionSection: function() {
        if(this.selectedModels.length > 1) {
            this.$('.actions').removeClass('hidden');
            $('#sidebar .primary .actions').addClass('hidden');
        } else {
            this.$('.actions').addClass("hidden");
            $('#sidebar .primary .actions').removeClass('hidden');
        }
    },

    deselectAll: function(e) {
        e.preventDefault();
        chorus.PageEvents.trigger("selectNone");
    },

    additionalContext: function() {
        var actions = _.map(this.actions, this.templateValues);
        return {
            selectedModels: this.selectedModels,
            modelCount: this.selectedModels.length,
            actions: actions
        };
    },

    postRender: function() {
        this.showOrHideMultipleSelectionSection();
        this._super("postRender");
    }


});
