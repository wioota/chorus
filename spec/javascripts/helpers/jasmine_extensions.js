jasmine.MAX_PRETTY_PRINT_DEPTH = 5;

jasmine.Spec.prototype.useFakeTimers = function() {
    var clock = sinon.useFakeTimers.apply(sinon, arguments);
    this.after(function() {clock.restore();});
    return clock;
};