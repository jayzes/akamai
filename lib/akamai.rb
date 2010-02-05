require 'tempfile'
require 'net/ftp'
require 'soap/wsdlDriver'

module Akamai
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    
    attr_accessor :cachecontrol_username, 
                  :cachecontrol_password,
                  :netstorage_username, 
                  :netstorage_password,
                  :netstorage_ftp_host,
                  :netstorage_public_host,
                  :netstorage_basedir,
                  :wsdl_url

    def initialize
      self.wsdl_url = 'http://ccuapi.akamai.com/ccuapi-axis.wsdl'
    end
    
  end
  
  def self.purge(*urls)
    driver = SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
    driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
    driver.options["protocol.http.basic_auth"] << [WSDL_URL, self.configuration.cachecontrol_username, self.configuration.cachecontrol_password]
    result = driver.purgeRequest(self.configuration.cachecontrol_username, self.configuration.cachecontrol_password, '', [], urls)
    return result.resultCode == '100'
  end
  
  def self.put(location, filename)
    Tempfile.open(filename)  do |tempfile| 
    
      # write to the tempfile
      tempfile.write(yield)
      tempfile.flush
      
      puts "Tempfile generated for #{filename} at #{tempfile.path}."

      ftp = Net::FTP::new(self.configuration.netstorage_ftp_host)
      ftp.passive = true
    
      ftp.login(self.configuration.netstorage_username, self.configuration.netstorage_password)
      ftp.chdir(self.configuration.netstorage_basedir) if self.configuration.netstorage_basedir
      ftp.chdir(self.configuration.location)

      ftp.put(tempfile.path, "#{filename}.new")
      ftp.delete(filename) unless ftp.ls(filename)
      ftp.rename("#{filename}.new", filename)
      ftp.close

      puts "Akamai upload completed for #{filename}."
      
      tempfile.close
      puts "Generated file deleted from tmp."

      puts "Sending purge request"
      purge_result = purge("http://#{self.configuration.netstorage_public_host}/#{location}/#{filename}")
      puts "Purge request #{ self.configuration.purge_result ? 'was successful' : 'failed' }."
    end
  end
  
end
