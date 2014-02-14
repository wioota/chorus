module Chorus
  module VERSION #:nodoc:
    MAJOR         = 3
    MINOR         = 0
    SERVICE_PACK  = 6
    PATCH         = 0

    STRING = [MAJOR, MINOR, SERVICE_PACK, PATCH, ENV['BUILD_NUMBER']].compact.join('.')
  end
end
