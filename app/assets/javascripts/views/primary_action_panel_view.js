chorus.views.PrimaryActionPanel = chorus.views.Base.extend({
    constructorName: "PrimaryActionPanel",
    templateName: "primary_action_panel",

    setup: function (options) {
        this.actions = this.options.actions || [];
        this.events = this.eventBindings(options.actions);
    },

    additionalContext: function () {
        return { actions: _.map(this.actions, this.templateValues) };
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
            new target({pageModel: this.options.pageModel}).launchModal();
        };
        var navigator = function (e) {
            e.preventDefault();
            chorus.router.navigate(target);
        };

        var targetIsConstructor = target instanceof Function;
        return targetIsConstructor ? dialogLauncher : navigator;
    },

    templateValues: function (action) {
        return { name: action.name, message: t('actions.' + action.name) };
    }
});
