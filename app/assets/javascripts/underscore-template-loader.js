// See https://github.com/Gazler/Underscore-Template-Loader

// $(document).ready(function() {
//   $('#load_remote_template').click(function() {
//     templateLoader.loadRemoteTemplate("test_template", "templates/test_template.txt", function(data) {
//       var compiled = _.template(data);
//       $('#content').html(compiled({name : 'world'}));
//     });
//   });
// });

(function() {
  var templateLoader = {
    templateVersion: "0.0.1",
    templates: {},
    queue: jQuery({}),
    loadRemoteTemplate: function(filename, callback) {
      var templateName = filename;
            
      if (this.templates[templateName]) {
        callback(this.templates[templateName]);
      }
      else {
        this.queue.queue(templateName, callback);
        if (this.templates[templateName] == undefined) {
          this.templates[templateName] = false;
          var self = this;
          jQuery.get(filename, function(data) {
            self.addTemplate(templateName, data);
            self.saveLocalTemplates();
            while (self.queue.queue(templateName).length > 0) {
              var cb = self.queue.queue(templateName).pop();
              cb(data);
            }
          });
        }
      }
    },
    
    addTemplate: function(templateName, data) {
      this.templates[templateName] = data;
    },
    
    localStorageAvailable: function() {
     try {
        return false;
        // TODO figure out versioning before enabling localStorage
        // return 'localStorage' in window && window['localStorage'] !== null;
      } catch (e) {
        return false;
      }
    },
    
    saveLocalTemplates: function() {
      if (this.localStorageAvailable()) {
        localStorage.setItem("templates", JSON.stringify(this.templates));
        localStorage.setItem("templateVersion", this.templateVersion);
      }
    },
    
    loadLocalTemplates: function() {
      if (this.localStorageAvailable()) {
        var templateVersion = localStorage.getItem("templateVersion");
        if (templateVersion && templateVersion == this.templateVersion) {
          var templates = localStorage.getItem("templates");
          if (templates) {
            templates = JSON.parse(templates);
            for (var x in templates) {
              if (!this.templates[x]) {
                this.addTemplate(x, templates[x]);
              }
            }
          }
        }
        else {
          localStorage.removeItem("templates");
          localStorage.removeItem("templateVersion");
        }
      }
    }

    
    
  };
  templateLoader.loadLocalTemplates();
  window.templateLoader = templateLoader;
})();
