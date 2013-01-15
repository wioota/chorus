chorus.utilities.TagItemManager = function() { };

chorus.utilities.TagItemManager.prototype = {
    init: function(core) {
        this.displayCount = core._opts.displayCount;
    },

    filter: function(list, query) {
        return list;
    },

    itemContains: function(item, needle) {
        return true;
    },

    stringToItem: function(str) {
        return {name: str};
    },

    itemToString: function(item) {
        if(this.displayCount) {
            return item.name + " (" + item.count + ")";
        } else {
            return item.name;
        }
    },

    compareItems: function(item1, item2) {
        return _.strip(item1.name.toLowerCase()) === _.strip(item2.name.toLowerCase());
    }
};