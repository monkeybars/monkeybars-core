class InvalidHashKeyError < Exception; end

module ValidatedHash
  # Raises an exception if a key in the hash does not exist in the list of valid keys
  def validate_only *keys
    self.keys.each {|key| raise InvalidHashKeyError.new("#{key} is not a valid key for this hash") unless keys.member?(key)}
  end
  
  # Raises an exception if any of the keys provided are not found in the hash
  def validate_all *keys
    keys.each {|key| raise InvalidHashKeyError.new("#{key} is required for this hash") unless self.keys.member?(key)}
  end
  
  # Raises an exception if any of the keys provided are found in the hash
  def validate_none *keys
    keys.each {|key| raise InvalidHashKeyError.new("#{key} is not allowed for this hash") if self.keys.member?(key)}
  end
end

class Hash
  include ValidatedHash
end
