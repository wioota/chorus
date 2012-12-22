(function() {
    chorus.Mixins.Fetching = {
        fetchIfNotLoaded: function(options) {
            if (this.loaded) {
                return;
            }
            if (!this.fetching) {
                this.fetch(options);
            }
        },

        fetchAllIfNotLoaded: function() {
            if (this.loaded) {
                if(this.models.length >= this.pagination.records) {
                    return;
                } else {
                    this.loaded = false;
                }
            }
            if (!this.fetching) {
                this.fetchAll();
            }
        },

        makeSuccessFunction: function(options, success) {
            return function(collection, data, xhr) {
                if (!options.silent) {
                    collection.trigger('loaded');
                }
                if (success) {
                    success(collection, data, xhr);
                }
            };
        },

        underscoreKeys: transformKeys(_.underscored),
        camelizeKeys: transformKeys(_.camelize),

        fetch: function(options) {
            this.fetching = true;
            options || (options = {});
            options.parse = true;
            var success = options.success, error = options.error;
            options.success = this.makeSuccessFunction(options, success);
            options.error = function(collection_or_model, xhr) {
                collection_or_model.handleRequestFailure("fetchFailed", xhr);
                if (error) error(collection_or_model, xhr);
            };

            return this._super('fetch', [options]).always(_.bind(function() {
                this.fetching = false;
            }, this));
        },

        parse: function(data, xhr) {
            this.loaded = true;
            this.pagination = data.pagination;
            delete this.serverErrors;
            var response = data.hasOwnProperty('response') ? data.response : data;
            return this.camelizeKeys(response);
        },

        handleRequestFailure: function(failureEvent, xhr, options) {
            var data = xhr.responseText && !!xhr.responseText.trim() && JSON.parse(xhr.responseText);
            this.parseErrors(data);
            this.trigger(failureEvent, this);
            this.respondToErrors(xhr.status, options);
        },

        parseErrors: function(data) {
            this.errorData = data.response;
            this.serverErrors = data.errors;
        },

        respondToErrors: function(status, options) {
            options = options || {};

            status = parseInt(status, 10);
            if (status === 401) {
                chorus.session.trigger("needsLogin");
            } else if (status === 403) {
                this.trigger("resourceForbidden");
            } else if (status === 404) {
                options.notFound ? options.notFound() : this.trigger("resourceNotFound");
            } else if (status === 422) {
                options.unprocessableEntity ? options.unprocessableEntity() : this.trigger("unprocessableEntity");
            } else if (status === 500) {
                var toastOpts = {};
                if(window.INTEGRATION_MODE) { toastOpts.sticky = true; }
                chorus.toast("server_error", {toastOpts: toastOpts});
            }
        }
    };

    function transformKeys(keyFn) {
        var transformer = function(hash) {
            var result = _.isArray(hash) ? [] : {};
            _.each(hash, function(val, key) {
                var newKey = keyFn(key);
                if (_.isObject(val) && newKey !== "errorObjects") {
                    result[newKey] = transformer(val);
                } else {
                    result[newKey] = val;
                }
            }, this);
            return result;
        };

        return transformer;
    }
})();

