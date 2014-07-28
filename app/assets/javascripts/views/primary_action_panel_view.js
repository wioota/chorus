chorus.views.PrimaryActionPanel = chorus.views.Base.extend({
    constructorName: "PrimaryActionPanel",
    templateName: "primary_action_panel",

    setup: function () {
        this.events = this.eventBindings(this.options.actions);
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
        return this.model.loaded && this.model.canUpdate() && this.model.isActive();
    },

    eventBindings: function (actions) {
        var bindEvent = function (events, action) {
            events[("click a." + action.name)] = this.launcherFunction(action.target);
            return events;
        };

        return _.reduce(actions, bindEvent, {}, this);
    },

    launcherFunction: function (target) {
        var dialogLauncher = function () { new target({workspace: this.model}).launchModal(); };
        var navigator = function () { chorus.router.navigate(target); };

        var targetIsConstructor = target instanceof Function;
        return targetIsConstructor ? dialogLauncher : navigator;
    }
});

