require "hache"
require "logger"
require "mote"
require "requests"
require "xmlsimple"

module PX
  UID = ENV.fetch("PX_UID")
  KEY = ENV.fetch("PX_KEY")

  SUCCESS_URL = ENV.fetch("PX_SUCCESS_URL")
  FAIL_URL = ENV.fetch("PX_FAIL_URL")

  TYPES = [
    TYPE_AUTH     = "Auth",
    TYPE_PURCHASE = "Purchase",
    TYPE_COMPLETE = "Complete",
    TYPE_VALIDATE = "Validate",
    TYPE_REFUND   = "Refund",
  ]

  def self.request(data)
    Util.post(Request, data)
  end

  def self.response(data)
    Util.post(Response, data)
  end

  def self.post(data)
    Util.post(PxPost, data)
  end

  module Util
    def self.post(strategy, data)
      xml = strategy.build(data)

      begin
        response = Requests.request("POST", strategy::URL, data: xml)

        strategy.parse(response.body)
      rescue Requests::Error => err
        log(:error, strategy.name, err.inspect)

        return nil
      end
    end

    def self.logger=(logger)
      @logger = logger
    end
    @logger = Logger.new(STDERR)

    def self.log(type, namespace, text)
      @logger.send(type, "%s -- %s" % [namespace, text])
    end
  end

  module Request
    extend Mote::Helpers

    XML = File.expand_path("../xml/request.xml", __FILE__)

    # Endpoint for Request / Response related posts
    URL = "https://sec.paymentexpress.com/pxpay/pxaccess.aspx"

    # <Request valid="1">
    #   <URI>https://sec.paymentexpress.com/pxmi3/XXXX</URI>
    # </Request>
    def self.parse(xml)
      dict = XmlSimple.xml_in(xml, forcearray: false)

      if dict["valid"] == "1" && dict["URI"]
        dict["URI"]
      else
        PX::Util.log(:warn, self.name, dict.inspect)
      end
    end

    def self.build(data)
      params = {
        uid: UID,
        key: KEY,
        ref: data.fetch(:ref, ""),
        type: data.fetch(:type, TYPE_AUTH),
        amount: data.fetch(:amount, "1"),
        currency: data.fetch(:currency, "USD"),
        data1: data.fetch(:data1, ""),
        data2: data.fetch(:data2, ""),
        data3: data.fetch(:data3, ""),
        email: data.fetch(:email),
        txn_id: data.fetch(:txn_id, ""),
        add_bill_card: data.fetch(:add_bill_card, true),
        success_url: data.fetch(:success_url, SUCCESS_URL),
        fail_url: data.fetch(:fail_url, FAIL_URL),
        this: Hache,
      }

      mote(XML, params)
    end
  end

  module Response
    extend Mote::Helpers

    XML = File.expand_path("../xml/response.xml", __FILE__)

    # Endpoint for Request / Response related posts
    URL = "https://sec.paymentexpress.com/pxpay/pxaccess.aspx"

    def self.parse(xml)
      dict = XmlSimple.xml_in(xml, forcearray: false)

      if dict["valid"] == "1" && dict["Success"] == "1"
        # Provide a more agnostic term so outside code
        # fetching it won't look too tied to PX.
        dict[:token] = dict["DpsBillingId"]

        return dict
      else
        PX::Util.log(:warn, self.name, dict.inspect)
      end
    end

    def self.build(data)
      params = {
        uid: UID,
        key: KEY,
        response: data.fetch(:response),
        this: Hache,
      }

      mote(XML, params)
    end
  end

  module PxPost
    extend Mote::Helpers

    USERNAME = ENV.fetch("PX_USERNAME")
    PASSWORD = ENV.fetch("PX_PASSWORD")

    # PX Post endpoint; used in conjunction with DpsBillingId
    # and the Token billing strategy.
    URL = "https://sec.paymentexpress.com/pxpost.aspx"

    XML = File.expand_path("../xml/post.xml", __FILE__)

    def self.parse(xml)
      dict = XmlSimple.xml_in(xml, forcearray: false)

      data = dict["Transaction"]

      if data["success"] == "1" && data["responseText"] == "APPROVED"
        return data
      else
        PX::Util.log(:warn, self.name, dict.inspect)
      end
    end

    def self.build(data)
      params = {
        uid: USERNAME,
        key: PASSWORD,

        # required parameters
        amount: data.fetch(:amount),

        # required, but with sane defaults.
        currency: data.fetch(:currency, "USD"),
        type: data.fetch(:type, TYPE_PURCHASE),

        # mandatory recommendations even though
        # they're optional in the API.
        txn_id: data.fetch(:txn_id, ""),
        ref: data.fetch(:ref, ""),
        token: data.fetch(:token),

        this: Hache,
      }

      mote(XML, params)
    end
  end
end
