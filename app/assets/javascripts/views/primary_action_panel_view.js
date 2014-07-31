chorus.views.PrimaryActionPanel = chorus.views.Base.extend({
    constructorName: "PrimaryActionPanel",
    templateName: "primary_action_panel",

    setup: function (options) {
        this.events = this.eventBindings(options.actions);
    },

    additionalContext: function () {
        var templateValues = function (action) {
            return { name: action.name, message: t('actions.' + action.name) };
        };

        return { actions: _.map(this.options.actions, templateValues) };
    },

    eventBindings: function (actions) {
        var bindEvent = function (events, action) {
            events[("click a." + action.name)] = this.launcherFunction(action.target);
            return events;
        };

        return _.reduce(actions, bindEvent, {}, this);
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
    }
});
