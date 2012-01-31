require 'tempfile'
require 'net/ftp'
require 'soap/wsdlDriver'
require 'akamai/version'

module Akamai
  class << self
    attr_accessor :configuration
    attr_writer :connection
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.connection
    @connection ||= Connection.new(configuration)
  end

  class Configuration
    attr_accessor :cachecontrol_username, 
                  :cachecontrol_password,
                  :cachecontrol_domain,
                  :cachecontrol_purge_action,
                  :netstorage_username, 
                  :netstorage_password,
                  :netstorage_ftp_host,
                  :netstorage_public_host,
                  :netstorage_basedir,
                  :wsdl_url

    def initialize(args = {})
      self.wsdl_url = 'http://ccuapi.akamai.com/ccuapi-axis.wsdl'
      self.cachecontrol_domain = "production"
      self.cachecontrol_purge_action = "remove"

      for key, val in args
        send("#{key}=".to_sym, val)
      end
    end
    
  end

  class Connection
    attr_accessor :config

    def initialize(args = {})
      @config = args.kind_of?(Configuration) ? args : Configuration.new(args)
    end

    def driver
      return @driver if @driver

      @driver = SOAP::WSDLDriverFactory.new(config.wsdl_url).create_rpc_driver
      @driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
      @driver.options["protocol.http.basic_auth"] << [config.wsdl_url, config.cachecontrol_username, config.cachecontrol_password]
      @driver
    end

    def purge(*urls)
      result = driver.purgeRequest(config.cachecontrol_username, config.cachecontrol_password, '', ["domain=#{config.cachecontrol_domain}", "action=#{config.cachecontrol_purge_action}"], urls)
      raise PurgeError, result.inspect unless result.resultCode == '100'
      true
    end

    class Error < StandardError
    end
    class PurgeError < StandardError
    end
  end

  def self.purge(*urls)
    connection.purge(*urls)
  end  
  
  def self.put(location, filename)
    Tempfile.open(filename)  do |tempfile| 
    
      # write to the tempfile
      tempfile.write(yield)
      tempfile.flush
      
      puts "Tempfile generated for #{filename} at #{tempfile.path}."
      
      put_file(tempfile.path, location, filename)
      
      tempfile.close
      puts "Generated file deleted from tmp."

    end
  end
    
  def self.put_file(local_path, location, filename)
    ftp = Net::FTP::new(self.configuration.netstorage_ftp_host)
    ftp.passive = true
  
    ftp.login(self.configuration.netstorage_username, self.configuration.netstorage_password)
    ftp.chdir(self.configuration.netstorage_basedir) if self.configuration.netstorage_basedir
    ftp.chdir(location)

    ftp.put(local_path, "#{filename}.new")
    ftp.delete(filename) unless ftp.ls(filename)
    ftp.rename("#{filename}.new", filename)
    ftp.close

    puts "Akamai upload completed for #{filename}."
    
    puts "Sending purge request"
    purge_result = purge("http://#{self.configuration.netstorage_public_host}/#{location}/#{filename}")
    puts "Purge request #{ purge_result ? 'was successful' : 'failed' }."
  end
  
end
