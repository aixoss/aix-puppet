require 'yaml'

module Automation
  module Lib
    # #########################################################################
    #  Class SpLevel
    #  Utility class to perform checks and processing on WWW-XX-YY-ZZZZ format
    # #########################################################################

    class SpLevel
      include Comparable
      attr_reader :aix
      attr_reader :rel
      attr_reader :tl
      attr_reader :sp

      # #######################################################################
      # name : initialize
      # param :input:aix:string
      # param :input:rel:string
      # param :input:tl:string
      # param :input:sp:string
      # description : constructor
      # #######################################################################
      def initialize(aix, rel, tl, sp)
        @aix = aix.to_i
        @rel = rel.to_i
        @tl = tl.to_i
        @sp = sp.to_i
      end

      # #######################################################################
      # name : same_release?
      # param : input:other
      # description : two SpLevel are considered from being in
      #  same release if they have same aix and rel values.
      # #######################################################################
      def same_release?(other)
        @aix == other.aix && @rel == other.rel
      end

      # #######################################################################
      # name : compare
      # description : to compare two SpLevel
      # #######################################################################
      def <=>(other)
        if @aix < other.aix
          -1
        elsif @aix > other.aix
          1
        elsif @rel < other.rel
          -1
        elsif @rel > other.rel
          1
        elsif @tl < other.tl
          -1
        elsif @tl > other.tl
          1
        elsif @sp < other.sp
          -1
        elsif @sp > other.sp
          1
        else
          0
        end
      end

      # #######################################################################
      # name : to_s
      # description : to stringify
      # #######################################################################
      def to_s
        "#{@aix}.#{@rel}.#{format('%02d', @tl)}.#{format('%02d', @sp)}"
      end

      # #######################################################################
      # name : version
      # param : input:hr_version:string  (hr means human readable)
      # return :
      # description : transforms "7.1" into "7100" and "7.2" into "7200"
      # #######################################################################
      def self.version(hr_version)
        hr_version[0] + hr_version[2] + '00'
      end

      # #######################################################################
      # name : hr_version  (hr means human readable)
      # param : input:version:string
      # return :
      # description : transforms "7100" into "7.1" and "7200" into "7.2"
      # #######################################################################
      def self.hr_version(version)
        version[0] + '.' + version[1]
      end

      # #######################################################################
      # name : technical_level
      # param : input:hr_version:string  (hr means human readable)
      # param : input:index:string
      # return :
      # description : generates "{technical_level="7100-01",
      #   hr_technical_level="7.1 TL1"} from "7.1, 1" parameters etc.
      # #######################################################################
      def self.technical_level(hr_version, index)
        version = SpLevel.version(hr_version)
        returned = {}
        index_padded = if index < 10
                         '0' + index.to_s
                       else
                         index.to_s
                       end
        technical_level = version + '-' + index_padded
        returned[:technical_level] = technical_level
        hr_technical_level = hr_version + ' TL' + index.to_s
        returned[:hr_technical_level] = hr_technical_level
        returned
      end

      # #######################################################################
      # name : validate_sp
      # param : input:key:string
      # param : input:value:string
      # return : true if value respects WWWW-XX-YY-ZZZZ format, false otherwise
      # description : validate against regexp
      # #######################################################################
      def self.validate_sp(key, value)
        returned = true
        lvl = Regexp.last_match(1) \
if value.to_s =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})/
        if lvl.nil?
          Log.log_err('validating "' + key + '" : parameter must be under the WWWW-XX-YY-ZZZZ format')
          returned = false
        else
          Log.log_debug('validating ' + key + ':' + value + ' respects the WWW-XX-YY-ZZZZ format')
        end
        returned
      end

      # #######################################################################
      # name : validate_tl
      # param : input:key:string
      # param : input:value:string
      # return : true if value respects WWWW-XX format, false otherwise
      # description : validate against regexp
      # #######################################################################
      def self.validate_tl(key, value)
        returned = true
        lvl = Regexp.last_match(1) if value.to_s =~ /^([0-9]{4}-[0-9]{2})/
        if lvl.nil?
          Log.log_err('validating "' + key + '" : parameter must be under the WWWW-XX format')
          returned = false
        else
          Log.log_debug('validating ' + key + ':' + value + ' respects the WWW-XX format')
        end
        returned
      end

      # #######################################################################
      # name : validate_sp_tl
      # param : input:key:string
      # param : input:value:string
      # return : true if value respects either WWWW-XX-YY-ZZZZ format or
      #  WWWW-XX format, false otherwise
      # description : validate against regexp
      # #######################################################################
      def self.validate_sp_tl(key, value)
        returned = true
        lvl1 = Regexp.last_match(1) if value.to_s =~ /^([0-9]{4}-[0-9]{2})/
        lvl2 = Regexp.last_match(1) if value.to_s =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})/
        if lvl1.nil? && lvl2.nil?
          Log.log_err('validating "' + key + '" : parameter must be either under the WWWW-XX \
format or under the WWWW-XX-YY-ZZZZ format')
          returned = false
        else
          Log.log_debug('validating ' + key + ':' + value + ' respects the WWW-XX format') unless lvl1.nil?
          unless lvl2.nil?
            Log.log_debug('validating ' + key + ':' + value + ' respects the WWW-XX-YY-ZZZZ format')
          end
        end
        returned
      end

      # #######################################################################
      # name : sp_exists
      # param : input:sp:string service pack string for example 7100-01-06-1241
      # return : true if sp exists, false otherwise
      # description : does this SP exist as suma SP.
      #  Check is done against sp_per_tl.yml.
      # #######################################################################
      def self.sp_exists(sp)
        returned = false
        sps_per_tl = Facter.value(:servicepacks)
        # take 7 first characters of sp and
        Log.log_debug('sp=' + sp)
        version = sp[0..6]
        # Log.log_debug('version=' + version)
        sps_of_tl = sps_per_tl[version]
        Log.log_debug('Possible sps_of_tl[' + version + ']=' + sps_of_tl.to_s)
        if !sps_of_tl.nil?
          returned = true if sps_of_tl.include? sp
        else
          returned = false
        end
        returned
      end

      # #######################################################################
      # name : tl_exists
      # param : input:tl:string technical level string for example 7100-02
      # return : true if tl exists, false otherwise
      # description : does this TL exist as suma TL.
      #  Check is done against sp_per_tl.yml.
      # #######################################################################
      def self.tl_exists(tl)
        returned = false
        sps_per_tl = Facter.value(:servicepacks)
        # take 7 first characters of sp and
        technical_levels = sps_per_tl.keys
        returned = true if technical_levels.include? tl
        returned
      end

      # #######################################################################
      # name : sp_tl_exists
      # param : input:sp_tl:string
      #   either a technical level string for example 7100-02
      #   or     a service pack level string for example 7100-01-06-1241
      # return : true if sp exists or tl exists, false otherwise
      # description : does this SP or TL exists either as a data TL
      #   or as a data SP.
      #  Check is done against sp_per_tl.yml.
      # #######################################################################
      def self.sp_tl_exists(sp_tl)
        returned = SpLevel.tl_exists(sp_tl)
        returned ||= SpLevel.sp_exists(sp_tl)
        returned
      end
    end # SpLevel
  end
end
