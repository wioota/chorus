chorus.Mixins.Events = {
    forwardEvent: function(eventName, target) {
        this.bind(eventName, function() {
            var args = _.toArray(arguments);
            args.unshift(eventName);
            target.trigger.apply(target, args);
        });
    },

    bindOnce: function(eventName, callback, context) {
        var callbacksForThisEvent = this._callbacks && this._callbacks[eventName];
        var callbackAlreadyBound = false;
        if (callbacksForThisEvent){
            var tail = callbacksForThisEvent.tail;
            while ((callbacksForThisEvent = callbacksForThisEvent.next) !== tail) {
                if (callbacksForThisEvent.callback === callback && callbacksForThisEvent.context === context) {
                    callbackAlreadyBound = true;
                    break;
                }
            }
        }
        if (callbackAlreadyBound) return;

        this.bind(eventName, callback, context);
        this.bind(eventName, unbinder, this);

        function unbinder() {
            this.unbind(eventName, callback, context);
            this.unbind(eventName, unbinder, this);
        }
    },

    shouldTriggerImmediately: function(eventName) {
        return false
    }
};
