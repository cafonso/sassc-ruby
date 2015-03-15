require_relative "error"

module SassC
  class Engine
    def initialize(template, options = {})
      @template = template
      @options = options
    end

    def render
      data_context = Native.make_data_context(@template)
      context = Native.data_context_get_context(data_context)
      native_options = Native.context_get_options(context)

      Native.option_set_is_indented_syntax_src(native_options, true) if sass?
      Native.option_set_input_path(native_options, filename) if filename
      Native.option_set_include_path(native_options, load_paths)

      import_handler.setup(native_options)
      functions_handler.setup(native_options)

      status = Native.compile_data_context(data_context)

      if status != 0
        message = Native.context_get_error_message(context)
        raise SyntaxError.new(message)
      end

      css = Native.context_get_output_string(context)

      @dependencies = Native.context_get_included_files(context)

      Native.delete_data_context(data_context)

      return css unless quiet?
    end

    def dependencies
      raise NotRenderedError unless @dependencies
      Dependency.from_filenames(@dependencies)
    end

    private

    def quiet?
      @options[:quiet]
    end

    def filename
      @options[:filename]
    end

    def sass?
      @options[:syntax] && @options[:syntax].to_sym == :sass
    end

    def import_handler
      @import_handler ||= ImportHandler.new(@options)
    end

    def functions_handler
      @functions_handler = FunctionsHandler.new(@options)
    end

    def load_paths
      paths = @options[:load_paths]
      paths.join(":") if paths
    end
  end
end
