class Log
  class << self
    def logger
      @logger ||= Logger.new($stdout)
    end

    def info(*args)
      logger.info(*args)
    end

    def debug(*args)
      logger.debug(*args)
    end

    def warn(*args)
      logger.warn(*args)
    end

    def error(*args)
      logger.error(*args)
    end

    def fatal(*args)
      logger.fatal(*args)
    end

    def unknown(*args)
      logger.unknown(*args)
    end

    def debug?
      logger.debug?
    end
  end
end
