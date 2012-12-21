chorus.Mixins.Events = {
    forwardEvent: function(eventName, target) {
        this.bind(eventName, function() {
            var args = _.toArray(arguments);
            args.unshift(eventName);
            target.trigger.apply(target, args);
        });
    },

    bindOnce: function(eventName, callback, context) {
        var callbacksForThisEvent = this._events && this._events[eventName];
        if (callbacksForThisEvent){
            var found = _.any (callbacksForThisEvent, function(binding) {
                return binding.callback._callback === callback && binding.context === context;
            });

            if(found) { return true; }
        }
        this.once(eventName, callback, context);
    },

    shouldTriggerImmediately: function(eventName) {
        return false
    }
};
