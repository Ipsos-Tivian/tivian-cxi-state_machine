module PluginAWeek #:nodoc:
  module Acts #:nodoc:
    # A state machine is a model of behavior composed of states, transitions,
    # and events.
    # 
    # Parts of definitions courtesy of http://en.wikipedia.org/wiki/Finite_state_machine.
    # 
    # Switch example:
    # 
    #   class Switch < ActiveRecord::Base
    #     acts_as_state_machine :initial => :off
    #     
    #     state :off
    #     state :on
    #     
    #     event :turn_on do
    #       transition_to :on, :from => :off
    #     end
    #     
    #     event :turn_off do
    #       transition_to :off, :from => :on
    #     end
    #   end
    module StateMachine
      # An unknown state was specified
      class InvalidState < Exception #:nodoc:
      end
      
      # An unknown event was specified
      class InvalidEvent < Exception #:nodoc:
      end
      
      # No initial state was specified for the machine
      class NoInitialState < Exception #:nodoc:
      end
      
      module SupportingClasses #:nodoc:
        # A state stores information about the past; i.e. it reflects the input
        # changes from the system start to the present moment.
        class State
          attr_reader :record
          delegate    :name, :id, :to => :record
          
          def initialize(record, options) #:nodoc:
            options.symbolize_keys!.assert_valid_keys(
              :before_enter,
              :after_enter,
              :before_exit,
              :after_exit,
              :deadline_passed_event
            )
            options.reverse_merge!(
              :deadline_passed_event => "#{record.name}_deadline_passed"
            )
            
            @record, @options = record, options
          end
          
          # Gets the name of the event that should be invoked when the state's
          # deadline has passed
          def deadline_passed_event
            "#{@options[:deadline_passed_event]}!"
          end
          
          # Indicates that the state is being entered
          def entering(record, args = [])
            run_actions(record, args, :before_enter)
          end
          
          # Indicates that the state has been entered.  If a deadline needs to
          # be set when this state is being entered, "set_#{name}_deadline"
          # should be defined in the record's class.
          def entered(record, args = [])
            # If the class supports deadlines, then see if we can set it now
            if record.class.use_state_deadlines && record.respond_to?("set_#{name}_deadline")
              record.send("set_#{name}_deadline")
            end
            
            run_actions(record, args, :after_enter)
          end
          
          # Indicates the the state is being exited
          def exiting(record, args = [])
            run_actions(record, args, :before_exit)
          end
          
          # Indicates the the state has been exited
          def exited(record, args = [])
            run_actions(record, args, :after_exit)
          end
          
          private
          def run_actions(record, args, action_type) #:nodoc:
            if actions = @options[action_type]
              Array(actions).each do |action|
                record.send(:run_transition_action, action, args)
              end
            end
          end
        end
        
        # A transition indicates a state change and is described by a condition
        # that would need to be fulfilled to enable the transition.  Transitions
        # consist of:
        # * The starting state
        # * The ending state
        # * A guard to check if the transition is allowed
        class StateTransition
          attr_reader :from_name,
                      :to_name,
                      :options
          
          def initialize(from_name, to_name, options) #:nodoc:
            options.symbolize_keys!.assert_valid_keys(:if)
            
            @from_name, @to_name = from_name.to_s, to_name.to_s
            @guards = Array(options[:if])
          end
          
          # Ensures that the transition can occur by checking the guards
          # associated with it
          def guard(record, args)
            @guards.all? {|guard| record.send(:run_transition_action, guard, args)}
          end
          
          # Runs the actual transition and any actions associated with entering
          # and exiting the states
          def perform(record, args)
            return false unless guard(record, args)
            
            loopback = record.state_name == to_name
            
            next_state = record.class.states[to_name]
            last_state = record.class.states[record.state_name]
            
            # Start leaving the last state
            last_state.exiting(record, args) unless loopback
            
            # Start entering the next state
            next_state.entering(record, args) unless loopback
            
            record.state = next_state.record
            
            # Leave the last state
            last_state.exited(record, args) unless loopback
            
            # Enter the next state
            next_state.entered(record, args) unless loopback
            
            true
          end
          
          def ==(obj) #:nodoc:
            @from_name == obj.from_name && @to_name == obj.to_name
          end
        end
        
        # An event is a description of activity that is to be performed at a
        # given moment.
        class Event
          attr_writer :valid_state_names
          attr_reader :record
          
          delegate    :name, :id, :to => :record
          
          def initialize(record, options, transitions, valid_state_names, &block) #:nodoc:
            options.symbolize_keys!.assert_valid_keys(
              :parallel
            )
            
            @record, @options, @valid_state_names = record, options, valid_state_names
            @transitions = transitions[name] = []
            
            instance_eval(&block) if block_given?
          end
          
          # Gets all of the possible next states for the record
          def next_states(record)
            @transitions.select {|transition| transition.from_name == record.state_name}
          end
          
          # Attempts to transition to one of the next possible states.  If it is
          # successful, then any parallel machines that have been configured
          # will have their events fired as well
          def fire(record, args)
            success = false
            
            # Find a state that we can transition into
            original_state_name = record.state_name
            next_states(record).each do |transition|
              if success = transition.perform(record, args)
                record.record_transition(name, original_state_name, record.state_name)
                break
              end
            end
            
            # Execute the event on all other state machines running in parallel
            if success && parallel_state_machines = options[:parallel]
              @parallel_state_machines ||= [parallel_state_machines].flatten.inject({}) do |machine_events, machine|
                if machine.is_a?(Hash)
                  machine_events.merge(machine)
                else
                  machine_events[machine] = name
                end
                machine_events
              end
              
              @parallel_state_machines.each do |machine, event|
                machine = Symbol === machine ? record.send(machine) : machine.call(self)
                success = machine.send("#{event}!", *args)
                
                break if !success
              end
            end
            
            success
          end
          
          # Creates a new transition to the specified state.
          # 
          # Configuration options:
          # <tt>from</tt> - A state or array of states that can be transitioned to
          # <tt>if</tt> - An optional condition that must be met for the transition to occur
          def transition_to(to_name, options = {})
            raise InvalidState, "#{to_name} is not a valid state for #{self.name}" unless @valid_state_names.include?(to_name.to_s)
            
            options.symbolize_keys!
            
            Array(options.delete(:from)).each do |from_name|
              raise InvalidState, "#{from_name} is not a valid state for #{self.name}" unless @valid_state_names.include?(from_name.to_s)
              
              @transitions << SupportingClasses::StateTransition.new(from_name, to_name, options)
            end
          end
        end
      end
      
      def self.included(base) #:nodoc:
        base.extend(MacroMethods)
      end
      
      module MacroMethods
        # Configuration options:
        # * <tt>initial</tt> - The initial state to place each record in.  This can either be a string/symbol or a Proc for dynamic initial states.
        # * <tt>use_deadlines</tt> - Whether or not deadlines will be used for states.
        def acts_as_state_machine(options)
          options.assert_valid_keys(
            :initial,
            :use_deadlines
          )
          raise NoInitialState unless options[:initial]
          
          options.reverse_merge!(:use_deadlines => false)
          
          model_name = "::#{self.name}"
          model_assoc_name = model_name.demodulize.underscore
          
          # Create the State model
          const_set('State', Class.new(::State)).class_eval do
            has_many  :changes,
                        :class_name => "#{model_name}::StateChange"
            has_many  :deadlines,
                        :class_name => "#{model_name}::StateDeadline"
          end
          
          # Create a model for recording each change in state
          const_set('Event', Class.new(::Event)).class_eval do
            has_many  :state_changes,
                        :class_name => "#{model_name}::StateChange"
          end
          
          # Create a model for recording each change in state
          const_set('StateChange', Class.new(::StateChange)).class_eval do
            belongs_to  :event,
                          :class_name => "#{model_name}::Event",
                          :foreign_key => 'event_id'
            belongs_to  :from_state,
                          :class_name => "#{model_name}::State",
                          :foreign_key => 'to_state_id'
            belongs_to  :to_state,
                          :class_name => "#{model_name}::State",
                          :foreign_key => 'to_state_id'
            belongs_to  :stateful,
                          :class_name => model_name,
                          :foreign_key => 'stateful_id',
                          :dependent => :destroy
            
            alias_method    model_assoc_name, :stateful
            alias_attribute "#{model_assoc_name}_id", :stateful_id
          end
          
          # Create a model for tracking a deadline for each state
          use_deadlines = options[:use_deadlines]
          if use_deadlines
            const_set('StateDeadline', Class.new(::StateDeadline)).class_eval do
              belongs_to  :state,
                            :class_name => "#{model_name}::State",
                            :foreign_key => 'to_state_id'
              belongs_to  :stateful,
                            :class_name => model_name,
                            :foreign_key => 'stateful_id',
                            :dependent => :destroy
              
              alias_method    model_assoc_name, :stateful
              alias_attribute "#{model_assoc_name}_id", :stateful_id
            end
          end
          
          write_inheritable_attribute :states, {}
          write_inheritable_attribute :initial_state_name, options[:initial]
          write_inheritable_attribute :transitions, {}
          write_inheritable_attribute :events, {}
          write_inheritable_attribute :use_state_deadlines, use_deadlines
          
          class_inheritable_reader    :states
          class_inheritable_reader    :transitions
          class_inheritable_reader    :events
          class_inheritable_reader    :use_state_deadlines
          
          before_create               :set_initial_state_id
          after_create                :run_initial_state_actions
          
          const_set('StateExtension', Module.new).class_eval do
            def find_in_states(number, state_names, *args)
              @reflection.klass.with_state_scope(state_names) do
                find(number, *args)
              end
            end
          end
          
          belongs_to  :state,
                        :class_name => "#{model_name}::State",
                        :foreign_key => 'state_id'
          has_many    :state_changes,
                        :class_name => "#{model_name}::StateChange",
                        :foreign_key => 'stateful_id',
                        :dependent => :destroy
          has_many    :state_deadlines,
                        :class_name => "#{model_name}::StateDeadline",
                        :foreign_key => 'stateful_id',
                        :dependent => :destroy if use_deadlines
          
          extend PluginAWeek::Acts::StateMachine::ClassMethods
          include PluginAWeek::Acts::StateMachine::InstanceMethods
        end
      end
      
      module InstanceMethods
        def self.included(base) #:nodoc:
          base.class_eval do
            alias_method_chain :state, :initial_check
          end
        end
        
        # Gets the name of the initial state that records will be placed in.
        def initial_state_name
          name = self.class.read_inheritable_attribute(:initial_state_name)
          name = name.call(self) if name.is_a?(Proc)
          
          name
        end
        
        # Gets the actual State record for the initial state
        def initial_state
          self.class.states[initial_state_name.to_s].record
        end
        
        # Gets the state of the record.  If this record has not been saved, then
        # the initial state will be returned.
        def state_with_initial_check
          state_without_initial_check || (new_record? ? initial_state : nil)
        end
        
        # Gets the state id of the record.  If this record has not been saved,
        # then the id of the initial state will be returned.
        def state_id
          read_attribute(:state_id) || (new_record? ? state.id : nil)
        end
        
        # The name of the current state the object is in
        def state_name
          state.name
        end
        
        # Returns what the next state for a given event would be, as a Ruby symbol.
        def next_state_for_event(event_name)
          next_states = next_states_for_event(event_name)
          next_states.empty? ? nil : next_states.first.to_sym
        end
        
        # Returns all of the next possible states for a given event, as Ruby symbols.
        def next_states_for_event(event_name)
          self.class.transitions[event_name.to_s].select do |transition|
            transition.from_name == state_name
          end.map {|transition| transition.to_name.to_sym}
        end
        
        #
        def record_transition(event_name, from_state_name, to_state_name)
          from_record = self.class.states[from_state_name].record if from_state_name
          to_record = self.class.states[to_state_name].record
          
          state_attrs = {
            :to_state_id => to_record.id,
            :occurred_at => Time.now
          }
          state_attrs[:event_id] = self.class.events[event_name].id if event_name
          state_attrs[:from_state_id] = from_record.id if from_record
          
          state_changes.create(state_attrs)
          
          if self.class.use_state_deadlines && send("#{to_state_name}_deadline")
            send("clear_#{to_state_name}_deadline")
          end
        end
        
        #
        def after_find
          check_deadlines
        end
        
        #
        def check_deadlines(options = {})
          transitioned = false
          
          if self.class.use_state_deadlines
            current_deadline = send("#{state_name}_deadline")
            
            if current_deadline && current_deadline <= Time.now
              state = self.class.states[state_name]
              transitioned = send(state.deadline_passed_event, options)
            end
          end
          
          transitioned
        end
        
        private
        #
        def set_initial_state_id
          self.state_id = state.id if read_attribute(:state_id).nil?
        end
        
        #
        def run_initial_state_actions
          if state_changes.empty?
            transaction(self) do
              state = self.class.states[initial_state_name.to_s]
              state.entering(self)
              state.entered(self)
              
              record_transition(nil, nil, state.name)
            end
          end
        end
        
        #
        def run_transition_action(action, args)
          Symbol === action ? send(action, *args) : action.call(*args.unshift(self))
        end
      end
      
      module ClassMethods
        # Returns an array of all known states.
        def state_names
          states.keys
        end
        
        # Define a state of the system. +state+ can take an optional Proc object
        # which will be executed every time the system transitions into that
        # state.  The proc will be passed the current object.
        #
        # Example:
        #
        # class Order < ActiveRecord::Base
        #   acts_as_state_machine :initial => :open
        #
        #   state :open
        #   state :closed, Proc.new { |o| Mailer.send_notice(o) }
        # end
        def state(name, options = {})
          name = name.to_s
          record = self::State.find_by_name(name)
          raise InvalidState, "#{name} is not a valid state for #{self.name}" unless record
          
          states[name] = SupportingClasses::State.new(record, options)
          
          class_eval <<-end_eval
            def #{name}?
              state_id == #{record.id}
            end
            
            def #{name}_at
              state_change = state_changes.find_by_to_state_id(#{record.id}, :order => 'occurred_at DESC')
              state_change.occurred_at if !state_change.nil?
            end
          end_eval
          
          # Add support for checking deadlines
          if use_state_deadlines
            class_eval <<-end_eval
              def #{name}_deadline
                state_deadline = state_deadlines.find_by_state_id(#{record.id})
                state_deadline.deadline if state_deadline
              end
              
              def #{name}_deadline=(value)
                state_deadlines.create(:state_id => #{record.id}, :deadline => value)
              end
              
              def clear_#{name}_deadline
                state_deadlines.find_by_state_id(#{record.id}).destroy
              end
            end_eval
          end
          
          self::StateExtension.module_eval <<-end_eval
            def #{name}(*args)
              with_scope(:find => {:conditions => ["\#{aliased_table_name}.state_id = ?", #{record.id}]}) do
                find(args.first.is_a?(Symbol) ? args.shift : :all, *args)
              end
            end
            
            def #{name}_count(*args)
              with_scope(:find => {:conditions => ["\#{aliased_table_name}.state_id = ?", #{record.id}]}) do
                count(*args)
              end
            end
          end_eval
        end
        
        # Returns an array of all known states.
        def event_names
          events.keys
        end
        
        # Define an event.  This takes a block which describes all valid transitions
        # for this event.
        #
        # Example:
        #
        # class Order < ActiveRecord::Base
        #   acts_as_state_machine :initial => :open
        #
        #   state :open
        #   state :closed
        #
        #   event :close_order do
        #     transitions :to => :closed, :from => :open
        #   end
        # end
        #
        # +transitions+ takes a hash where <tt>:to</tt> is the state to transition
        # to and <tt>:from</tt> is a state (or Array of states) from which this
        # event can be fired.
        #
        # This creates an instance method used for firing the event.  The method
        # created is the name of the event followed by an exclamation point (!).
        # Example: <tt>order.close_order!</tt>.
        def event(name, options = {}, &block)
          name = name.to_s
          record = self::Event.find_by_name(name)
          raise InvalidEvent, "#{name} is not a valid event for #{self.name}" unless record
          
          if event = events[name]
            # The event has already been defined, so just evaluate the new
            # block.  The state names will be redefined since it is likely this
            # is being called from a subclass.
            event.valid_state_names = state_names
            event.instance_eval(&block) if block
          else
            events[name] = SupportingClasses::Event.new(record, options, transitions, state_names, &block)
            
            # Add action for transitioning the model
            class_eval <<-end_eval
              def #{name}!(*args)
                run_initial_state_actions if new_record?
                
                success = false
                transaction(self) do
                  event = self.events[#{name.dump}]
                  if success = event.fire(self, args)
                    success = save if !new_record?
                  end
                  
                  rollback if !success
                end
                
                success
              end
            end_eval
          end
        end
        
        # Wraps ActiveRecord::Base.find to conveniently find all records in
        # a given set of states.  Options:
        #
        # * +number+ - This is just :first or :all from ActiveRecord +find+
        # * +state+ - The state to find
        # * +args+ - The rest of the args are passed down to ActiveRecord +find+
        def find_in_states(number, state_names, *args)
          with_state_scope(state_names) do
            find(number, *args)
          end
        end
        
        # Wraps ActiveRecord::Base.count to conveniently count all records in
        # a given set of states.  Options:
        #
        # * +states+ - The states to find
        # * +args+ - The rest of the args are passed down to ActiveRecord +find+
        def count_in_states(state_names, *args)
          with_state_scope(state_names) do
            count(*args)
          end
        end
        
        # Wraps ActiveRecord::Base.calculate to conveniently calculate all
        # records in a given set of states.  Options:
        #
        # * +states+ - The states to find
        # * +args+ - The rest of the args are passed down to ActiveRecord +calculate+
        def calculate_in_state(state_names, *args)
          with_state_scope(state_names) do
            calculate(*args)
          end
        end
        
        # Creates a :find scope for matching certain state names.  We can't use
        # the cached records or check if the states are real because subclasses
        # which add additional states may not necessarily have been added yet.
        def with_state_scope(state_names)
          state_names = Array(state_names).map(&:to_s)
          if state_names.size == 1
            state_conditions = ['states.name = ?', state_names.first]
          else
            state_conditions = ['states.name IN (?)', state_names]
          end
          
          with_scope(:find => {:include => :state, :conditions => state_conditions}) do
            yield
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include PluginAWeek::Acts::StateMachine
end