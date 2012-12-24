class MCollective::Application::Iptables<MCollective::Application
  description "Linux IP Tables Junkfilter Client"
  usage "iptables [block|unblock|isblocked] 1.2.3.4"

  option :silent,
         :description    => "Do not wait for results",
         :arguments      => "-s",
         :type           => :bool

  def post_option_parser(configuration)
    if ARGV.size == 2
      configuration[:command] = ARGV.shift
      configuration[:ipaddress] = ARGV.shift
    end
  end

  def validate_configuration(configuration)
    raise "Command should be one of block, unblock or isblocked" unless ["block", "unblock", "isblocked"].include?(configuration[:command])
    raise "Please provide an IP address" unless configuration[:ipaddress]
  end

  def main
    iptables = rpcclient("iptables")

    if configuration[:silent]
      puts "Sent request %s" % iptables.send(configuration[:command], {:ipaddr => configuration[:ipaddress], :process_results => false})
    else
      iptables.send(configuration[:command], {:ipaddr => configuration[:ipaddress]}).each do |node|
        if iptables.verbose
          if node[:data][:output]
            puts "%40s:  %s" % [node[:sender], node[:data][:output]]
          else
            puts "%40s:  %s" % [node[:sender], node[:statusmsg]]
          end
        else
          case configuration[:command]
            when "block", "unblock"
              puts "%40s:  %s" % [node[:sender], node[:statusmsg]] unless node[:statuscode] == 0
            when "isblocked"
              puts "%40s:  %s" % [node[:sender], node[:data][:blocked]]
            end
        end
      end

      puts

      printrpcstats :summarize => true

      halt iptables.stats
    end
  end
end
