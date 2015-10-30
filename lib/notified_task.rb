# encoding: utf-8
class NotifiedTask < Rake::TaskLib
  attr_accessor :name, :block

  def initialize(name, &block)
    @name = name
    @block = block
    define
  end

  def define
    task name do |t|
      begin
        block.call
      rescue Exception => exception
        @exception = exception
        template = File.read("app/views/layouts/system_error.erb")
        result = ERB.new(template, nil, "<>").result(binding)
        Rails.logger.error("ERROR: #{result}")
        AdminMailer.system_error(exception, result).deliver
        raise exception
      end
    end
  end
end
