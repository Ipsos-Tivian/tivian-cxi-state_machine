require 'state_machine/guard'
require 'state_machine/eval_helpers'

module PluginAWeek #:nodoc:
  module StateMachine
    # Callbacks represent hooks into objects that allow you to trigger logic
    # before or after a specific transition occurs.
    class Callback
      include EvalHelpers
      
      class << self
        # Whether to automatically bind the callback to the object being
        # transitioned.  This only applies to callbacks that are defined as
        # lambda blocks (or Procs).  Some libraries, such as Extlib, handle
        # callbacks by executing them bound to the object involved, while other
        # libraries, such as ActiveSupport, pass the object as an argument to
        # the callback.  This can be configured on an application-wide basis by
        # setting this configuration to +true+ or +false+.  The default value
        # is +false+.
        # 
        # *Note* that the DataMapper and Sequel integrations automatically
        # configure this value on a per-callback basis, so it does not have to
        # be enabled application-wide.
        # 
        # == Examples
        # 
        # When not bound to the object:
        # 
        #   class Vehicle
        #     state_machine do
        #       before_transition do |vehicle|
        #         vehicle.set_alarm
        #       end
        #     end
        #     
        #     def set_alarm
        #       ...
        #     end
        #   end
        # 
        # When bound to the object application-wide:
        # 
        #   PluginAWeek::StateMachine::Callback.bind_to_object = true
        #   
        #   class Vehicle
        #     state_machine do
        #       before_transition do
        #         self.set_alarm
        #       end
        #     end
        #     
        #     def set_alarm
        #       ...
        #     end
        #   end
        attr_accessor :bind_to_object
      end
      
      # An optional block for determining whether to cancel the callback chain
      # based on the return value of the callback.  By default, the callback
      # chain never cancels based on the return value (i.e. there is no implicit
      # terminator).  Certain integrations, such as ActiveRecord, change this
      # default value.
      # 
      # == Examples
      # 
      # Canceling the callback chain without a terminator:
      # 
      #   class Vehicle
      #     state_machine do
      #       before_transition do |vehicle|
      #         throw :halt
      #       end
      #     end
      #   end
      # 
      # Canceling the callback chain with a terminator value of +false+:
      # 
      #   class Vehicle
      #     state_machine do
      #       before_transition do |vehicle|
      #         false
      #       end
      #     end
      #   end
      attr_reader :terminator
      
      # The guard that determines whether or not this callback can be invoked
      # based on the context of the transition.  The event, from state, and
      # to state must all match in order for the guard to pass.
      # 
      # See PluginAWeek::StateMachine::Guard for more information.
      attr_reader :guard
      
      # Creates a new callback that can get called based on the configured
      # options.
      # 
      # In addition to the possible configuration options for guards, the
      # following options can be configured:
      # * +bind_to_object+ - Whether to bind the callback to the object involved.  If set to false, the object will be passed as a parameter instead.  Default is integration-specific or set to the application default.
      # * +terminator+ - A block/proc that determines what callback results should cause the callback chain to halt (if not using the default <tt>throw :halt</tt> technique).
      # 
      # More information about how those options affect the behavior of the
      # callback can be found in their attr_accessor definitions.
      def initialize(options = {}, &block) #:nodoc:
        if options.is_a?(Hash)
          @method = options.delete(:do) || block
        else
          # Only the callback was configured
          @method = options
          options = {}
        end
        
        # The actual method to invoke must be defined
        raise ArgumentError, ':do callback must be specified' unless @method
        
        # Proxy the method so that it's bound to the object
        @method = bound_method(@method) if @method.is_a?(Proc) && (!options.include?(:bind_to_object) && self.class.bind_to_object || options.delete(:bind_to_object))
        @terminator = options.delete(:terminator)
        
        @guard = Guard.new(options)
      end
      
      # Runs the callback as long as the transition context matches the guard
      # requirements configured for this callback.
      def call(object, context = {}, *args)
        # Only evaluate the method if the guard passes
        if @guard.matches?(object, context)
          result = evaluate_method(object, @method, *args)
          
          # If a terminator has been configured and it matches the result from
          # the evaluated method, then the callback chain should be halted
          if @terminator && @terminator.call(result)
            throw :halt
          else
            result
          end
        end
      end
      
      private
        # Generates an method that can be bound to the object being transitioned
        # when the callback is invoked
        def bound_method(block)
          # Generate a thread-safe unbound method that can be used on any object
          unbound_method = Object.class_eval do
            time = Time.now
            method_name = "__bind_#{time.to_i}_#{time.usec}"
            define_method(method_name, &block)
            method = instance_method(method_name)
            remove_method(method_name)
            method
          end
          arity = unbound_method.arity
          
          # Proxy calls to the method so that the method can be bound *and*
          # the arguments are adjusted
          lambda do |object, *args|
            unbound_method.bind(object).call(*(arity == 0 ? [] : args))
          end
        end
    end
  end
end
