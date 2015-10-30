#encoding: utf-8
class Jobs::Job
  # extend Resque::Plugins::ExponentialBackoff
  # 
  # def self.backoff_strategy
  #   return [0, 60, 300, 900, 3600, 14400 ]  # 1m, 5m, 15m, 1h, 4h
  # end

  def self.queue
    "lll"
  end
  
  def self.run
    raise "run() should be overridden by subclass"
  end
  
  def self.perform(*args)
    begin
      self.run(*args)
    rescue Exception => exception
      report_error(exception)
      raise exception
    end
  end
  
  def self.report_error(exception)
    @exception = exception
    template = File.read("app/views/layouts/system_error.erb")
    result = ERB.new(template, nil, "<>").result(binding)
    Rails.logger.error("ERROR: #{result}")
    AdminMailer.system_error(exception, result).deliver    
  end
  
end