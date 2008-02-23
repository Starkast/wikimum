module ActionView
  module Helpers
    module FormTagHelper

      # Creates a submit button with the text <tt>value</tt> as the caption. If options contains a pair with the key of "disable_with",
      # then the value will be used to rename a disabled version of the submit button.
      # 
      # Patched so that all submit-buttons will belong to class "submit"
      # by default
      def submit_tag(value = "Save changes", options = {})
        options.stringify_keys!
        
        if disable_with = options.delete("disable_with")
          options["onclick"] = "this.disabled=true;this.value='#{disable_with}';this.form.submit();#{options["onclick"]}"
        end
          
        tag :input, { "class" => "submit", "type" => "submit", "name" => "commit", "value" => value }.update(options.stringify_keys)
      end
    end
  end
end
