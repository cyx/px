require "cutest"
require "securerandom"
require "open-uri"

ENV["PX_SUCCESS_URL"] = "http://openredis.com/"
ENV["PX_FAIL_URL"] = "http://openredis.com/"

require_relative "../lib/px"

# This will hit the live URL, so you'll have to have
# the proper UID / KEY to be able to test this properly.
test "PX.request" do
  data = {
    email: "cyx@cyx.is",
    txn_id: SecureRandom.hex(8),
    ref: SecureRandom.hex(16),
    type: PX::TYPE_AUTH,
    amount: 1,
    currency: "USD",
    add_bill_card: true
  }

  # Since we're passing trash data, we expect it
  # to not give us a URI response.
  uri = URI(PX.request(data))

  assert_equal "https", uri.scheme
  assert_equal "sec.paymentexpress.com", uri.host

  assert open(uri.to_s).read.include?("Credit Card Payment")

end if ENV["TEST_INTEGRATION"]

test "parse request (valid)" do
  request = <<-EOT
  <Request valid="1">
    <URI>https://sec.paymentexpress.com/pxmi3/XXXX</URI>
  </Request>
  EOT

  expected = "https://sec.paymentexpress.com/pxmi3/XXXX"

  assert_equal expected, PX::Request.parse(request)
end

test "parse response (valid)" do
  response = <<-EOT
    <Response valid="1">
      <Success>1</Success>
      <TxnType>Purchase</TxnType>
      <CurrencyInput>NZD</CurrencyInput>
      <MerchantReference>Purchase Example</MerchantReference>
      <TxnData1></TxnData1>
      <TxnData2></TxnData2>
      <TxnData3></TxnData3>
      <AuthCode>113837</AuthCode>
      <CardName>Visa</CardName>
      <CardHolderName>CARDHOLDER NAME</CardHolderName>
      <CardNumber>411111........11</CardNumber>
      <DateExpiry>1111</DateExpiry>
      <ClientInfo>192.168.1.111</ClientInfo>
      <TxnId>P03E57DA8A9DD700</TxnId>
      <EmailAddress></EmailAddress>
      <DpsTxnRef>000000060495729b</DpsTxnRef>
      <BillingId></BillingId>
      <DpsBillingId></DpsBillingId>
      <AmountSettlement>1.00</AmountSettlement>
      <CurrencySettlement>NZD</CurrencySettlement>
      <DateSettlement>20100924</DateSettlement>
      <TxnMac>BD43E619</TxnMac>
      <ResponseText>APPROVED</ResponseText>
      <CardNumber2></CardNumber2>
      <Cvc2ResultCode>M</Cvc2ResultCode>
    </Response>
  EOT

  dict = PX::Response.parse(response)

  assert dict.kind_of?(Hash)
end

test "response build" do
  xml = PX::Response.build(response: "foo")

  dict = XmlSimple.xml_in(xml, forcearray: false)

  assert_equal PX::UID, dict["PxPayUserId"]
  assert_equal PX::KEY, dict["PxPayKey"]
  assert_equal "foo", dict["Response"]
end

test "response live" do
  data = {
    response: "00000100491234332513213fb881cc01"
  }

  # puts PX.response(data).inspect

  assert_equal "0000010059278491", PX.response(data)[:token]
end if ENV["TEST_INTEGRATION"]

test "pxpost build" do
  data = {
    amount: 8,
    currency: "SGD",
    type: PX::TYPE_AUTH,
    txn_id: "txn1234",
    ref: "ref1234",
    token: "tok1234",
  }

  dict = XmlSimple.xml_in(PX::PxPost.build(data), forcearray: false)

  assert_equal PX::PxPost::USERNAME, dict["PostUsername"]
  assert_equal PX::PxPost::PASSWORD, dict["PostPassword"]
  assert_equal "8.00", dict["Amount"]
  assert_equal "SGD", dict["InputCurrency"]
  assert_equal PX::TYPE_AUTH, dict["TxnType"]
  assert_equal "txn1234", dict["TxnId"]
  assert_equal "ref1234", dict["MerchantReference"]
  assert_equal "tok1234", dict["DpsBillingId"]
end

test "pxpost POST" do
  data = {
    amount: 8,
    currency: "USD",
    type: PX::TYPE_PURCHASE,
    token: "0000010059278491"
  }

  dict = PX.post(data)

  assert_equal "1", dict["success"]
  assert_equal "APPROVED", dict["responseText"]
  assert_equal "1", dict["Authorized"]
  assert_equal "8.00", dict["Amount"]
  assert_equal "USD", dict["CurrencyName"]

end if ENV["TEST_INTEGRATION"]
