module Akamai

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
      opts = ["domain=#{config.cachecontrol_domain}", "action=#{config.cachecontrol_purge_action}"]
      opts << "email-notification=#{config.cachecontrol_email_notification}" if config.cachecontrol_email_notification
      result = driver.purgeRequest(config.cachecontrol_username, config.cachecontrol_password, '', opts, urls)
      raise PurgeError, result.inspect unless result.resultCode == '100'
      true
    end

  end
  
end