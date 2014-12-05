require 'socket'

module UsedPortsValidator
  def self.log(*args)
    puts *args
  end

  def self.run(ports_to_check)
    log "-"*20
    log "Checking for ports in use..."

    conflicting_ports = []
    ports_to_check.each do |p|
      begin
        r = TCPServer.new('localhost', p)
        r.close
      rescue Errno::EADDRINUSE
        log "  \e[#{5;31}mProblem: \e[#{0}mNetwork port #{p} is in use"
        conflicting_ports << p
      end
    end

    log "-"*20
    return conflicting_ports.empty?
  end
end