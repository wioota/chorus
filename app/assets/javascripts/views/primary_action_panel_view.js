chorus.views.PrimaryActionPanel = chorus.views.Base.extend({
    constructorName: "PrimaryActionPanel",
    templateName: "primary_action_panel",

    setup: function () {
        this.events = this.eventBindings(this.options.actions);
        _.extend(this, this.options.models);
    },

    additionalContext: function () {
        var templateValues = function (action) {
            return { name: action.name, message: t('actions.' + action.name) };
        };

        return {
            canUpdate: this.canUpdate(),
            actions: _.map(this.options.actions, templateValues)
        };
    },

    canUpdate: function() {
        return this.workspace.loaded && this.workspace.canUpdate() && this.workspace.isActive();
    },

    eventBindings: function (actions) {
        var bindEvent = function (events, action) {
            events[("click a." + action.name)] = this.launcherFunction(action.target);
            return events;
        };

        return _.reduce(actions, bindEvent, {}, this);
    },

    launcherFunction: function (target) {
        var dialogLauncher = function () { new target(this.options.models).launchModal(); };
        var navigator = function () { chorus.router.navigate(target); };

        var targetIsConstructor = target instanceof Function;
        return targetIsConstructor ? dialogLauncher : navigator;
    }
});

