module ConstantizeHelper
  def self.safe_constantize(options, default = nil)
    option = options.find { |opt| constantize(opt) }
    constantize(option || default)
  end

  def self.constantize(option)
    cst = option.to_s.safe_constantize
    return if cst.nil? || (cst.is_a?(Class) && cst.name != option.to_s)
    cst
  rescue LoadError
    nil
  end
end
