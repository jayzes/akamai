module Akamai
  
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
  
end