module Kernel
  def singleton_class
    class << self
      self
    end
  end unless defined?(singleton_class)
end
