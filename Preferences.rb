# Generic AR-style UserDefaults manipulation
class Preferences
  class << self
    
    def method_missing(name, *args)
      name = name.to_s
      if name =~ /^(.*)=$/ || name =~ /^set(.*)$/
        property_name = $1.gsub(/^\w/) { |c| c.downcase }
        define_property(property_name)
        return set(property_name, args.first)
      else
        define_property(name)
        return get(name)
      end
    end
    
    def get(name)
      defaults.objectForKey(name.to_s)
    end
    
    def set(name, value)
      defaults.setObject(value, forKey: name.to_s)
      return value
    end
    
    def get_all(*args)
      return args.map { |k| get(k) }
    end
    
    def update_all(hash = {})
      hash.each_pair { |k, v| set(k, v) }
      return true
    end
    
    def define_property(name)
      setter      = "#{name}="
      objC_setter = "set#{name.gsub(/^\w/) { |c| c.upcase }}"
      (class << self; self; end).class_eval do
        define_method(name)        { get(name) }
        define_method(setter)      { |value| set(name, value) }
        define_method(objC_setter) { |value| set(name, value) }
      end
    end
    
    def defaults
      @@defaults ||= NSUserDefaults.standardUserDefaults
    end
    
  end
end
