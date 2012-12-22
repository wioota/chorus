chorus.utilities.PageEvents = function chorus$PageEvents() {
    this.reset();
};

chorus.utilities.PageEvents.prototype.reset = function() {
    this.subscriptionIds = {};
    this.subscriptions = {};
    this.subscriptionHandles = {};
};

chorus.utilities.PageEvents.prototype.subscribe = function(eventName, callback, context, id) {
    if(id && this.subscriptionIds[id]) {
        return this.subscriptionIds[id];
    }
    this.subscriptions[eventName] || (this.subscriptions[eventName] = []);
    var handle = _.uniqueId();
    var binding = {callback: callback, context: context};
    this.subscriptionHandles[handle] = {eventName: eventName, binding: binding, id: id};
    this.subscriptions[eventName].push(binding);
    if(id) {
        this.subscriptionIds[id] = handle;
    }
    return handle;
};

chorus.utilities.PageEvents.prototype.unsubscribe = function(handleOrId) {
    var handle = this.subscriptionIds[handleOrId] || handleOrId;
    var fullHandle = this.subscriptionHandles[handle];
    if(!fullHandle) {
        return;
    }

    delete this.subscriptionIds[fullHandle.id];
    delete this.subscriptionHandles[handle];

    var eventName = fullHandle.eventName;
    this.subscriptions[eventName] = _.without(this.subscriptions[eventName], fullHandle.binding);
};

// Really only used for tests
chorus.utilities.PageEvents.prototype.hasSubscription = function(eventName, callback, context) {
    var eventMatches = this.subscriptions[eventName];

    return eventMatches && _.find(eventMatches, function(eventMatch) {
        return eventMatch.callback === callback && eventMatch.context === context;
    })
};

chorus.utilities.PageEvents.prototype.broadcast = function(eventName) {
    var list = this.subscriptions[eventName];
    if (!list) {
        return;
    }

    var args = _.toArray(arguments);
    args.shift();

    _.each(list, function(binding) {
        binding.callback.apply(binding.context, args);
    });
};
