chorus.presenters.DatasetSidebar = chorus.presenters.Base.extend({
    setup: function() {
        _.each(this.options, function(value, key) {
           this[key] = value;
        }, this);
    },

    typeString: function() {
        return Handlebars.helpers.humanizedDatasetType(this.resource && this.resource.attributes, this.resource && this.resource.statistics().attributes);
    },

    deleteMsgKey: function() {
        return this.deleteKey("deleteMsgKey");
    },

    deleteTextKey: function() {
        return this.deleteKey("deleteTextKey");
    },

    deleteKey: function(target) {
        var keyTable = {
            "CHORUS_VIEW": {
                deleteMsgKey: "delete",
                deleteTextKey: "actions.delete"
            },
            "SOURCE_TABLE_VIEW":{
                deleteMsgKey: "disassociate_view",
                deleteTextKey: "actions.delete_association"
            },
            "SOURCE_TABLE":{
                deleteMsgKey: "disassociate_table",
                deleteTextKey: "actions.delete_association"
            }
        }

        var resourceType = this.resource && this.resource.get("type");
        var resourceObjectType = this.resource && this.resource.get("objectType");

        var rescue = {};
        rescue[target] = "";
        var deleteMsgKey = (keyTable[resourceType + "_" + resourceObjectType] || keyTable[resourceType] || rescue)[target]

        return deleteMsgKey || "";
    },

    isDeleteable: function() {
        return this.hasWorkspace() && this.resource.isDeleteable() && this.resource.workspace().canUpdate();
    },

    workspaceId: function() {
        return this.hasWorkspace() && this.resource.workspace().id;
    },

    hasSandbox: function() {
        return this.hasWorkspace() && this.resource.workspace().sandbox();
    },

    hasWorkspace: function() {
        return this.resource && this.resource.workspace();
    },

    activeWorkspace: function() {
        return this.hasWorkspace() && this.resource.workspace().isActive();
    },

    isImportConfigLoaded: function() {
        return this.resource && this.resource.isImportConfigLoaded();
    },

    hasSchedule: function() {
        return this.resource && this.resource.importSchedule();
    },

    nextImport: function() {
        if(!this.hasSchedule()) return "";

        var importSchedule = this.resource.importSchedule();
        var nextImportStart = chorus.helpers.relativeTimestamp(importSchedule.get('nextImportAt'));
        if(importSchedule.get("destinationDatasetId") == null) {
            return chorus.helpers.safeT("import.next_import", {
                nextTime: nextImportStart,
                tableRef: this.ellipsize(importSchedule.destination().name())
            });
        } else {
            return chorus.helpers.safeT("import.next_import", {
                nextTime: nextImportStart,
                tableRef: this._linkToModel(importSchedule.destination())
            });
        }
    },

    inProgressText: function() {
        var lastDestination = this.resource && this.resource.lastImportDestination();

        if(!lastDestination) return "";

        var importStringKey;
        var lastImport = this.resource.lastImport();
        if(lastImport.get('sourceDatasetId') == this.resource.get('id')) {
            importStringKey = "import.in_progress";
        } else {
            importStringKey = "import.in_progress_into";
        }
        return chorus.helpers.safeT(importStringKey, { tableLink: this._linkToModel(lastDestination) });
    },

    importInProgress: function() {
        var lastImport = this.resource && this.resource.lastImport();
        return lastImport && lastImport.isInProgress();
    },

    importFailed: function() {
        var lastImport = this.resource && this.resource.lastImport();

        return lastImport && !this.importInProgress() && !lastImport.get('success');
    },

    lastImport: function () {
        var lastImport = this.resource && this.resource.lastImport();
        var importStatusKey, tableLink;

        if(!lastImport) {
            return "";
        }

        if(lastImport.isInProgress()) {
            var startedAt = chorus.helpers.relativeTimestamp(lastImport.get('startedStamp'));
            return chorus.helpers.safeT("import.began", { timeAgo: startedAt });
        }

        if(lastImport.get("sourceDatasetId") == this.resource.get("id")) {
            var destination = lastImport.destination();
            tableLink = this._linkToModel(destination);
            if(lastImport.get('success')) {
                importStatusKey = "import.last_imported";
            } else {
                importStatusKey = "import.last_import_failed";
            }
        } else {
            var source = lastImport.importSource();
            tableLink = (lastImport.get("fileName")) ?
                chorus.helpers.spanFor(this.ellipsize(lastImport.get("fileName")), { 'class': "source_file", title: lastImport.get("fileName") }) :
                this._linkToModel(source);
            if(lastImport.get('success')) {
                importStatusKey = "import.last_imported_into";
            } else {
                importStatusKey = "import.last_import_failed_into";
            }
        }

        var completedAt = chorus.helpers.relativeTimestamp(lastImport.get('completedStamp'));
        return chorus.helpers.safeT(importStatusKey, { timeAgo: completedAt, tableLink: tableLink });
    },

    noCredentialsWarning: function() {
        if(!this.resource) {
            return ""
        }

        var addCredentialsLink = chorus.helpers.linkTo("#", t("dataset.credentials.missing.linkText"), {'class': 'add_credentials'});
        var instanceName = this.resource.instance().name();
        return chorus.helpers.safeT("dataset.credentials.missing.body", {linkText: addCredentialsLink, instanceName: instanceName });
    },

    noCredentials: function() {
        return this.resource ? !this.resource.hasCredentials() : "";
    },

    isChorusView: function() {
        return this.resource ? this.resource.isChorusView() : "";
    },

    displayEntityType: function() {
        return this.resource ? this.resource.metaType() : "";
    },

    workspaceArchived: function() {
        return this.resource && this.resource.workspaceArchived();
    },

    canAnalyze: function() {
        return this.resource && this.resource.canAnalyze();
    },

    hasImport: function() {
        return this.resource && this.resource.hasImport();
    },

    canExport: function canExport() {
        return this.resource && this.resource.canExport();
    },

    _linkToModel: function(model) {
        return chorus.helpers.linkTo(model.showUrl(), this.ellipsize(model.name()), {title: model.name()});
    },

    ellipsize: function (name) {
        if (!name) return "";
        var length = 15;
        return (name.length < length) ? name : name.slice(0, length-3).trim() + "...";
    }
});
