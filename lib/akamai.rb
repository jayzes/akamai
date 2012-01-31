require 'tempfile'
require 'net/ftp'
require 'soap/wsdlDriver'

require 'akamai/version'
require 'akamai/errors'
require 'akamai/configuration'
require 'akamai/connection'

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
