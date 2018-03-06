require 'fluent/plugin/filter'
require 'json'
require 'net/http'
require 'openssl'

module Fluent::Plugin
  class HanarpMessage < Filter
    Fluent::Plugin.register_filter("hanarp_message", self)

    config_param :ucsHostNameKey, :string

    def filter(tag, time, record)

      split = record["message"].split(": ")

      message = split[4]

      event = record["event"]
      stage = record["stage"]
      host = record[ucsHostNameKey]
      chassis = message[/chassis-(\d)/,1]
      blade = message[/blade-(\d)/,1]

      if record.key?("machineId")
        machineId = record["machineId"]
        serviceProfile = machineId.split(":")[2]
      end

      d = Data.new(machineId, host, chassis, blade, serviceProfile, stage, message)
      m = Message.new(time, event, d)
      record["message"] = m.to_json
      record
    end
  end

  class Message
    def initialize(timestamp, event, data)
      @timestamp = timestamp
      @event = event
      @data = data
    end

    def to_json(*a)
      {
        timestamp: @timestamp,
        event: @event,
        data: @data
      }.to_json(*a)
    end
  end

  class Data
    def initialize(machineId, hostname, chassis, blade, serviceProfile, stage, message)
      @machineId = machineId
      @hostname = hostname
      @chassis = chassis
      @blade = blade
      @serviceProfile = serviceProfile
      @stage = stage
      @message = message
    end

    def to_json(*a)
      {
        machineId: @machineId,
        hostname: @hostname,
        chassis: @chassis,
        blade: @blade,
        serviceProfile: @serviceProfile,
        stage: @stage,
        message: @message
      }.to_json(*a)
    end
  end
end
