module StateMachine
  module ClassMethods
    def self.extended(base) #:nodoc:
      base.class_eval do
        @state_machines = {}
      end
    end
    
    # Gets the current list of state machines defined for this class.  This
    # class-level attribute acts like an inheritable attribute.  The attribute
    # is available to each subclass, each subclass having a copy of its
    # superclass's attribute.
    # 
    # The hash of state machines maps +attribute+ => +machine+, e.g.
    # 
    #   Vehicle.state_machines # => {:state => #<StateMachine::Machine:0xb6f6e4a4 ...>
    def state_machines
      @state_machines ||= superclass.state_machines.dup
    end
  end
  
  module InstanceMethods
    # Defines the initial values for state machine attributes.  The values
    # will be set *after* the original initialize method is invoked.  This is
    # necessary in order to ensure that the object is initialized before
    # dynamic initial attributes are evaluated.
    def initialize(*args, &block)
      super
      initialize_state_machines
    end
    
    # Runs one or more events in parallel.  All events will run through the
    # following steps:
    # * Before callbacks
    # * Persist state
    # * Invoke action
    # * After callbacks
    # 
    # For example, if two events (for state machines A and B) are run in
    # parallel, the order in which steps are run is:
    # * A - Before transition callbacks
    # * B - Before transition callbacks
    # * A - Persist new state
    # * B - Persist new state
    # * A - Invoke action
    # * B - Invoke action (only if different than A's action)
    # * A - After transition callbacks
    # * B - After transition callbacks
    # 
    # *Note* that multiple events on the same state machine / attribute cannot
    # be run in parallel.  If this is attempted, an ArgumentError will be
    # raised.
    # 
    # == Halting callbacks
    # 
    # When running multiple events in parallel, special consideration should
    # be taken with regard to how halting within callbacks affects the flow.
    # 
    # For *before* callbacks, any <tt>:halt</tt> error that's thrown will
    # immediately cancel the perform for all transitions.  As a result, it's
    # possible for one event's transition to affect the continuation of
    # another.
    # 
    # On the other hand, any <tt>:halt</tt> error that's thrown within an
    # *after* callback with only affect that event's transition.  Other
    # transitions will continue to run their own callbacks.
    # 
    # == Example
    # 
    #   class Vehicle
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #       
    #       event :park do
    #         transition :idling => :parked
    #       end
    #     end
    #     
    #     state_machine :hood_state, :namespace => 'hood', :initial => :closed do
    #       event :open do
    #         transition all => :opened
    #       end
    #       
    #       event :close do
    #         transition all => :closed
    #       end
    #     end
    #   end
    #   
    #   vehicle = Vehicle.new                       # => #<Vehicle:0xb7c02850 @state="parked", @hood_state="closed">
    #   vehicle.state                               # => "parked"
    #   vehicle.hood_state                          # => "closed"
    #   
    #   vehicle.fire_events(:ignite, :open_hood)    # => true
    #   vehicle.state                               # => "idling"
    #   vehicle.hood_state                          # => "opened"
    #   
    #   # If any event fails, the entire event chain fails
    #   vehicle.fire_events(:ignite, :close_hood)   # => false
    #   vehicle.state                               # => "idling"
    #   vehicle.hood_state                          # => "opened"
    #   
    #   # Exception raised on invalid event
    #   vehicle.fire_events(:park, :invalid)        # => ArgumentError: :invalid is an unknown event
    #   vehicle.state                               # => "idling"
    #   vehicle.hood_state                          # => "opened"
    def fire_events(*events)
      run_action = [true, false].include?(events.last) ? events.pop : true
      
      # Generate the transitions to run for each event
      transitions = events.collect do |name|
        # Find the actual event being run
        event = nil
        self.class.state_machines.detect do |attribute, machine|
          event ||= machine.events[name, :qualified_name]
        end
        
        raise ArgumentError, "#{name.inspect} is an unknown state machine event" unless event
        
        # Get the transition that will be performed for the event
        unless transition = event.transition_for(self)
          event.machine.invalidate(self, event)
        end
        
        transition
      end.compact
      
      # Run the events in parallel only if valid transitions were found for
      # all of them
      events.length == transitions.length ? StateMachine::Transition.perform(transitions, run_action) : false
    end
    
    # Run one or more events in parallel.  If any event fails to run, then
    # a StateMachine::InvalidTransition exception will be raised.
    # 
    # See StateMachine::InstanceMethods#fire_events for more information.
    # 
    # == Example
    # 
    #   class Vehicle
    #     state_machine :initial => :parked do
    #       event :ignite do
    #         transition :parked => :idling
    #       end
    #       
    #       event :park do
    #         transition :idling => :parked
    #       end
    #     end
    #     
    #     state_machine :hood_state, :namespace => 'hood', :initial => :closed do
    #       event :open do
    #         transition all => :opened
    #       end
    #       
    #       event :close do
    #         transition all => :closed
    #       end
    #     end
    #   end
    #   
    #   vehicle = Vehicle.new                       # => #<Vehicle:0xb7c02850 @state="parked", @hood_state="closed">
    #   vehicle.fire_events(:ignite, :open_hood)    # => true
    #   
    #   vehicle.fire_events!(:ignite, :open_hood)   # => 
    def fire_events!(*events)
      run_action = [true, false].include?(events.last) ? events.pop : true
      fire_events(*(events + [run_action])) || raise(StateMachine::InvalidTransition, "Cannot run events in parallel: #{events * ', '}")
    end
    
    protected
      def initialize_state_machines #:nodoc:
        self.class.state_machines.each do |attribute, machine|
          # Set the initial value of the machine's attribute unless it already
          # exists (which must mean the defaults are being skipped)
          value = send(attribute)
          send("#{attribute}=", machine.initial_state(self).value) if value.nil? || value.respond_to?(:empty?) && value.empty?
        end
      end
  end
end
