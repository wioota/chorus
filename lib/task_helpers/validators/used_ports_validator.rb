require 'socket'

module UsedPortsValidator
  def self.log(*args)
    puts *args
  end

  def self.run(ports_to_check)
    log "Checking for ports in use..."

    conflicting_ports = []
    ports_to_check.each do |p|
      begin
        r = TCPServer.new('localhost', p)
        r.close
        log "Success: Network port #{p} not in use"
      rescue Errno::EADDRINUSE
        log "Problem: Network port #{p} is in use"
        conflicting_ports << p
      end
    end

    return conflicting_ports.empty?
  end
end