module Economic
  class Entity
    class Handle
      attr_accessor :id, :number

      def initialize(hash)
        @id = hash[:id]
        @number = hash[:number]
      end

      def to_hash
        hash = {}
        hash['Id'] = id unless id.blank?
        hash['Number'] = number unless number.blank?
        hash
      end

      def [](key)
        {:id => @id, :number => @number}[key]
      end

      def ==(other)
        return false if other.nil?
        return false unless other.respond_to?(:id) && other.respond_to?(:number)
        self.id == other.id && self.number == other.number
      end
    end

    # Internal accessors
    attr_accessor :persisted, :session, :partial

    class << self
      def properties_not_triggering_full_load
        [:id, :number, :handle]
      end

      def has_properties(*properties)
        @properties = properties
        properties.each do |property|
          unless properties_not_triggering_full_load.include?(property) || instance_methods.collect(&:to_s).include?(property.to_s)
            # Create property accessors that loads the full Entity from the API if necessary
            define_method "#{property}" do
              value = instance_variable_get("@#{property}")
              if value.nil? && partial? && persisted?
                instance_variable_get("@#{property}")
              else
                value
              end
            end
          end

          # Just use regular writers
          attr_writer property
        end
      end

      def properties
        @properties || []
      end

      # Returns the class used to instantiate a proxy for Entity
      def proxy
        class_name = name.split('::').last
        proxy_class_name = "#{class_name}Proxy"
        Economic.const_get(proxy_class_name)
      end

      # Returns the E-conomic API action name to call
      def soap_action(action)
        class_name = self.name
        class_name_without_modules = class_name.split('::').last
        "#{class_name_without_modules.snakecase}_#{action.to_s.snakecase}".intern
      end
    end

    def handle
      Handle.new({:number => @number, :id => @id})
    end

    def initialize(properties = {})
      initialize_defaults
      update_properties(properties)
      @persisted = false
      @partial = true
    end

    def initialize_defaults
      nil
    end

    # Updates Entity with its data from the API
    def get_data
      response = proxy.get_data(number)
      self.update_properties(response)
      self.partial = false
      self.persisted = true
    end

    # Returns the number of Entity. This does not trigger a load from the API even if Entity is partial
    def number
      @number
    end

    # Returns the id of Entity. This does not trigger a load from the API even if Entity is partial
    def id
      @id
    end

    def handle
      handle = {}
      handle[:id] = id unless id.blank?
      handle[:number] = number unless number.blank?
      handle
    end

    # Returns true if CurrentInvoiceLine has been persisted in e-conomic
    def persisted?
      !!@persisted
    end

    # Returns true if Entity has not been fully loaded from API yet
    def partial?
      # TODO: Can this be introspected somehow?
      !!@partial
    end

    # Returns a proxy for entities of the current class. For example if called on an
    # Economic::Debtor it returns an instance of Economic::DebtorProxy with the Debtors session as
    # owner.
    def proxy
      self.class.proxy.new(session)
    end

    def inspect
      props = self.class.properties.collect { |p| "#{p}=#{self.send(p).inspect}" }
      "#<#{self.class}:#{self.object_id} partial=#{partial?}, persisted=#{persisted?}, #{props.join(', ')}>"
    end

    # Persist the Entity to the API
    def save
      create_or_update
    end

    # Updates properties of Entity with the values from hash
    def update_properties(hash)
      hash.each do |key, value|
        setter_method = "#{key}="
        if self.respond_to?(setter_method)
          self.send(setter_method, value)
        end
      end
    end

  protected

    def create_or_update
      if persisted?
        update
      else
        create
      end
    end

    def create
      response = session.request soap_action(:create_from_data) do
        soap.body = {'data' => build_soap_data}
      end

      if response
        @number = response[:number]
        @id = response[:id]
      end

      @persisted = true
      @partial = false

      return response
    end

    def update
      response = session.request soap_action(:update_from_data) do
        soap.body = {'data' => build_soap_data}
      end

      @persisted = true
      @partial = false

      return response
    end

    # Returns OrderedHash with the data structure to send to the API
    def build_soap_data
    end

    def soap_action(action)
      self.class.soap_action(action)
    end

  end

end