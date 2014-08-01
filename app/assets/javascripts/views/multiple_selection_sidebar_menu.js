chorus.views.MultipleSelectionSidebarMenu = chorus.views.Base.extend({
    constructorName: "MultiSelectionSidebarMenu",
    templateName: "multiple_selection_sidebar_menu",

    setup: function() {
        this.actions = this.options.actions || [];
        this.selectEvent = this.options.selectEvent;
        this.selectedModels = new chorus.collections.Base();
        this.events = this.eventBindings(this.actions, { "click .deselect_all": 'deselectAll' });
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
    },

    templateValues: function (action) {
        return { name: action.name, message: t('actions.' + action.name) };
    },

    eventBindings: function (actions, initialEvents) {
        var bindEvent = function (events, action) {
            events[("click a." + action.name)] = this.launcherFunction(action.target);
            return events;
        };

        return _.reduce(actions, bindEvent, initialEvents || {}, this);
    },

    launcherFunction: function (target) {
        var dialogLauncher = function (e) {
            e.preventDefault();
            new target({pageModel: this.options.pageModel, collection: this.selectedModels}).launchModal();
        };
        var navigator = function (e) {
            e.preventDefault();
            chorus.router.navigate(target);
        };

        var invoker = function (e) {
            e.preventDefault();
            this.selectedModels.invoke(target);
        };

        var targetIsConstructor = target instanceof Function;

        var targetIsURL = !targetIsConstructor && target.match(/\\/);

        return targetIsConstructor ? dialogLauncher : targetIsURL ? navigator : invoker;
    }
});
