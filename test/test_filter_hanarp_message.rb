require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_hanarp_message'
require 'json'

class AddServiceProfile < Test::Unit::TestCase
    def setup
        Fluent::Test.setup
    end

    CONFIG = %[
        @type hanarp_message
        ucsHostNameKey SyslogSource
      ]

    def create_driver(conf = CONFIG)
        Fluent::Test::Driver::Filter.new(Fluent::Plugin::HanarpMessage).configure(conf)
    end

    def filter(messages)
        d = create_driver
        d.run(default_tag: "default.tag") do
            messages.each do |message|
                d.feed(message)
            end
        end
        d.filtered_records
    end

    def test_configure
        d = create_driver
        assert_equal 'SyslogSource', d.instance.ucsHostNameKey
    end

    def test_filter
        messages = [
            { 
                "message" => ": 2018 Feb  9 21:07:41 GMT: %UCSM-6-EVENT: [] [FSM:BEGIN]: Soft shutdown of server sys/chassis-4/blade-7",
                "machineId" => "Cisco_UCS:SJC2:testServiceProfile",
                "SyslogSource" => "1.1.1.1",
                "event" => "Soft Shutdown",
                "stage" => "begin"
            }
        ]
        filtered_records = filter(messages)
        data = JSON.parse(filtered_records[0]['message'])
        
        assert_equal "Soft Shutdown", data['event']
        assert_equal "Cisco_UCS:SJC2:testServiceProfile", data['data']['machineId']
        assert_equal "1.1.1.1", data['data']['hostname']
        assert_equal "4", data['data']['chassis']
        assert_equal "7", data['data']['blade']
        assert_equal "testServiceProfile", data['data']['serviceProfile']
        assert_equal "begin", data['data']['stage']
        assert_equal "stopping", data['data']['state']
        
        assert_equal "Cisco_UCS:SJC2:testServiceProfile", filtered_records[0]['machineId']
        assert_equal "1.1.1.1", filtered_records[0]['SyslogSource']
    end

    def test_filter_missing_machine_id
        messages = [
            { 
                "message" => ": 2018 Feb  9 21:07:41 GMT: %UCSM-6-EVENT: [] [FSM:BEGIN]: Soft shutdown of server sys/chassis-4/blade-7",
                "SyslogSource" => "1.1.1.1",
                "event" => "Restart",
                "stage" => "end"
            }
        ]
        filtered_records = filter(messages)
        data = JSON.parse(filtered_records[0]['message'])
        
        assert_equal "Restart", data['event']
        assert_equal nil, data['data']['machineId']
        assert_equal "1.1.1.1", data['data']['hostname']
        assert_equal "4", data['data']['chassis']
        assert_equal "7", data['data']['blade']
        assert_equal nil, data['data']['serviceProfile']
        assert_equal "end", data['data']['stage']
        assert_equal "started", data['data']['state']
        
        assert_equal nil, filtered_records[0]['machineId']
        assert_equal "1.1.1.1", filtered_records[0]['SyslogSource']
    end

    def test_filter_unknown_state
        messages = [
            { 
                "message" => ": 2018 Feb  9 21:07:41 GMT: %UCSM-6-EVENT: [] [FSM:BEGIN]: Soft shutdown of server sys/chassis-4/blade-7",
                "machineId" => "Cisco_UCS:SJC2:testServiceProfile",
                "SyslogSource" => "1.1.1.1",
                "event" => "Unknown Event",
                "stage" => "begin"
            }
        ]
        filtered_records = filter(messages)
        data = JSON.parse(filtered_records[0]['message'])
        
        assert_equal "Unknown Event", data['event']
        assert_equal "Cisco_UCS:SJC2:testServiceProfile", data['data']['machineId']
        assert_equal "1.1.1.1", data['data']['hostname']
        assert_equal "4", data['data']['chassis']
        assert_equal "7", data['data']['blade']
        assert_equal "testServiceProfile", data['data']['serviceProfile']
        assert_equal "begin", data['data']['stage']
        assert_equal "unknown", data['data']['state']
        
        assert_equal "Cisco_UCS:SJC2:testServiceProfile", filtered_records[0]['machineId']
        assert_equal "1.1.1.1", filtered_records[0]['SyslogSource']
    end
end