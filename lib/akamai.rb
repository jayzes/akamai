require 'tempfile'
require 'net/ftp'
require 'soap/wsdlDriver'

module UserHome
  # ganked from railties
  def user_home
    if ENV['HOME']
      ENV['HOME']
    elsif ENV['USERPROFILE']
      ENV['USERPROFILE']
    elsif ENV['HOMEDRIVE'] and ENV['HOMEPATH']
      "#{ENV['HOMEDRIVE']}:#{ENV['HOMEPATH']}"
    else
      File.expand_path '~'
    end
  end
end

class Akamai
  
  extend UserHome
  
  WSDL_URL    = 'http://ccuapi.akamai.com/ccuapi-axis.wsdl'
  CONFIG_PATH = "#{user_home}/.akamai_config.yml"
  
  attr_accessor :cachecontrol_username, 
                :cachecontrol_password
                
  attr_accessor :netstorage_username, 
                :netstorage_password,
                :netstorage_ftp_host,
                :netstorage_public_host,
                :netstorage_basedir
                
  
  
  def initialize
    raise ArgumentError, "Config file (#{CONFIG_PATH}) could not be found" unless File.exists?(CONFIG_PATH)
    config = File.open(CONFIG_PATH) { |yf| YAML::load(yf) }
    self.cachecontrol_username   = config['cache_control']['username']
    self.cachecontrol_password   = config['cache_control']['password']
    self.netstorage_username     = config['netstorage']['username']
    self.netstorage_password     = config['netstorage']['password']
    self.netstorage_ftp_host     = config['netstorage']['ftp_host']
    self.netstorage_public_host  = config['netstorage']['public_host']
    self.netstorage_basedir      = config['netstorage']['basedir']
  end
    
  def purge(*urls)
    driver = SOAP::WSDLDriverFactory.new(WSDL_URL).create_rpc_driver
    driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
    driver.options["protocol.http.basic_auth"] << [WSDL_URL, cachecontrol_username, cachecontrol_password]
    result = driver.purgeRequest(cachecontrol_username, cachecontrol_password, '', [], urls)
    return result.resultCode == '100'
  end

  def put(location, filename)
    Tempfile.open(filename)  do |tempfile| 
    
      # write to the tempfile
      tempfile.write(yield)
      tempfile.flush
      
      puts "Tempfile generated for #{filename} at #{tempfile.path}."

      ftp = Net::FTP::new(netstorage_ftp_host)
      ftp.passive = true
    
      ftp.login(netstorage_username, netstorage_password)
      ftp.chdir(netstorage_basedir) if netstorage_basedir
      ftp.chdir(location)

      ftp.put(tempfile.path, "#{filename}.new")
      ftp.delete(filename) unless ftp.ls(filename)
      ftp.rename("#{filename}.new", filename)
      ftp.close

      puts "Akamai upload completed for #{filename}."
      
      tempfile.close
      puts "Generated file deleted from tmp."

      puts "Sending purge request"
      purge_result = purge("http://#{netstorage_public_host}/#{location}/#{filename}")
      puts "Purge request #{ purge_result ? 'was successful' : 'failed' }."
    end
  end
end
