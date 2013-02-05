chorus.Mixins.TagsContext = {
  additionalContextForTags: function() {
      return {
          tags: this.model.tags().models,
          workspaceIdForTagLink: this.options.workspaceIdForTagLink
      };
  }
};