require 'test_helper'
require 'bambora'

class BamboraTest < Test::Unit::TestCase

  def setup
    @gateway = BamboraGateway.new(
      merchant_id: '300205948',
      payments_api_key: 'D5544E039FEc4cb9b8bEc18F69a04f40',
    )

    @credit_card = credit_card('4030000010001234')
    @amount = 100

    @options = {
      order_id: '1',
      billing_address: {
        name: 'Johnny Smith',
        address1: '123 somestreet',
        zip: 'H1H1H1',
        country: 'CA'
      },
      description: 'Store Purchase'
    }
  end

  def test_successful_purchase
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_failed_purchase
    Bambora::API::Payment.expects(:create).returns(failed_purchase_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_authorize
    Bambora::API::Payment.expects(:preauth).returns(successful_authorize_response)
    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000028', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_failed_authorize
    Bambora::API::Payment.expects(:preauth).returns(failed_authorize_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_capture
    Bambora::API::Payment.expects(:preauth).returns(successful_authorize_response)
    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000028', response.authorization
    assert_equal 'Approved', response.message

    Bambora::API::Payment.expects(:complete).returns(successful_capture_response)
    response = @gateway.capture(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000029', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_failed_capture
    Bambora::API::Payment.expects(:preauth).returns(successful_authorize_response)
    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000028', response.authorization
    assert_equal 'Approved', response.message

    Bambora::API::Payment.expects(:complete).returns(failed_capture_response)
    response = @gateway.capture(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_refund
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message

    Bambora::API::Payment.expects(:return).returns(successful_refund_response)
    response = @gateway.refund(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000024', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_failed_refund
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message

    Bambora::API::Payment.expects(:return).returns(failed_refund_response)
    response = @gateway.refund(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_void
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message

    Bambora::API::Payment.expects(:void).returns(successful_void_response)
    response = @gateway.void(@credit_card, @options)
    assert_success response
    assert_equal '10000026', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_failed_void
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message

    Bambora::API::Payment.expects(:void).returns(failed_void_response)
    response = @gateway.void(@credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:processing_error], response.error_code
  end

  def test_successful_verify
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    Bambora::API::Payment.expects(:void).returns(successful_void_response)
    response = @gateway.verify(@credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_successful_verify_with_failed_void
    Bambora::API::Payment.expects(:create).returns(successful_purchase_response)
    Bambora::API::Payment.expects(:void).returns(failed_void_response)
    response = @gateway.verify(@credit_card, @options)
    assert_success response
    assert_equal '10000021', response.authorization
    assert_equal 'Approved', response.message
  end

  def test_failed_verify
    Bambora::API::Payment.expects(:create).returns(failed_purchase_response)
    response = @gateway.verify(@credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  # def test_scrub
  #   assert @gateway.supports_scrubbing?
  #   assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  # end

  private

  # def pre_scrubbed
  #   %q(
  #     Run the remote tests for this gateway, and then put the contents of transcript.log here.
  #   )
  # end
  #
  # def post_scrubbed
  #   %q(
  #     Put the scrubbed contents of transcript.log here after implementing your scrubbing function.
  #     Things to scrub:
  #       - Credit card number
  #       - CVV
  #       - Sensitive authentication details
  #   )
  # end

  def successful_purchase_response
    Bambora::API::PaymentResponse.new(
      JSON.parse(
        '{"id":"10000021","authorizing_merchant_id":300205948,"approved":"1","message_id":"1","message":"Approved","auth_code":"TEST","created":"2018-08-13T15:49:35","order_number":"7113128616","type":"P","payment_method":"CC","risk_score":0.0,"amount":79.76,"custom":{"ref1":"","ref2":"","ref3":"","ref4":"","ref5":""},"card":{"card_type":"VI","last_four":"2333","address_match":1,"postal_result":1,"avs_result":"1","cvd_result":"1","avs":{"id":"Y","message":"Street address and Postal/ZIP match.","processed":true}},"links":[{"rel":"void","href":"https://api.na.bambora.com/v1/payments/10000021/void","method":"POST"},{"rel":"return","href":"https://api.na.bambora.com/v1/payments/10000021/returns","method":"POST"}]}'
      )
    )
  end

  def failed_purchase_response
    Bambora::API::ErrorResponse.new(
      JSON.parse(
        '{"code":7,"category":1,"message":"DECLINE","reference":""}'
      )
    )
  end

  def successful_authorize_response
    Bambora::API::PaymentResponse.new(
      JSON.parse(
        '{"id":"10000028","authorizing_merchant_id":300205948,"approved":"1","message_id":"1","message":"Approved","auth_code":"TEST","created":"2018-08-13T15:49:39","order_number":"9328570403","type":"PA","payment_method":"CC","risk_score":0.0,"amount":74.37,"custom":{"ref1":"","ref2":"","ref3":"","ref4":"","ref5":""},"card":{"card_type":"VI","last_four":"2333","address_match":1,"postal_result":1,"avs_result":"1","cvd_result":"1","avs":{"id":"Y","message":"Street address and Postal/ZIP match.","processed":true}},"links":[{"rel":"complete","href":"https://api.na.bambora.com/v1/payments/10000028/completions","method":"POST"}]}'
      )
    )
  end

  def failed_authorize_response
    Bambora::API::ErrorResponse.new(
      JSON.parse('{}')
    )
  end

  def successful_capture_response
    Bambora::API::PaymentResponse.new(
      JSON.parse(
        '{"id":"10000029","authorizing_merchant_id":300205948,"approved":"1","message_id":"1","message":"Approved","auth_code":"TEST","created":"2018-08-13T15:49:39","order_number":"9328570403","type":"PAC","payment_method":"CC","risk_score":0.0,"amount":74.37,"custom":{"ref1":"","ref2":"","ref3":"","ref4":"","ref5":""},"card":{"card_type":"VI","address_match":0,"postal_result":0,"avs_result":"0","cvd_result":"1","cavv_result":"","avs":{"id":"U","message":"Address information is unavailable.","processed":false}},"links":[{"rel":"return","href":"https://api.na.bambora.com/v1/payments/10000029/returns","method":"POST"},{"rel":"complete","href":"https://api.na.bambora.com/v1/payments/10000029/completions","method":"POST"}]}'
      )
    )
  end

  def failed_capture_response
    Bambora::API::ErrorResponse.new(
      JSON.parse('{}')
    )
  end

  def successful_refund_response
    Bambora::API::PaymentResponse.new(
      JSON.parse(
        '{"id":"10000024","authorizing_merchant_id":300205948,"approved":"1","message_id":"1","message":"Approved","auth_code":"TEST","created":"2018-08-13T15:49:37","order_number":"8013982552","type":"R","payment_method":"CC","risk_score":0.0,"amount":10.00,"custom":{"ref1":"","ref2":"","ref3":"","ref4":"","ref5":""},"card":{"card_type":"VI","address_match":0,"postal_result":0,"avs_result":"0","cvd_result":"1","cavv_result":"","avs":{"id":"U","message":"Address information is unavailable.","processed":false}},"links":[{"rel":"void","href":"https://api.na.bambora.com/v1/payments/10000024/void","method":"POST"},{"rel":"return","href":"https://api.na.bambora.com/v1/payments/10000024/returns","method":"POST"}]}'
      )
    )
  end

  def failed_refund_response
    Bambora::API::ErrorResponse.new(
      JSON.parse('{}')
    )
  end

  def successful_void_response
    Bambora::API::PaymentResponse.new(
      JSON.parse(
        '{"id":"10000026","authorizing_merchant_id":300205948,"approved":"1","message_id":"1","message":"Approved","auth_code":"TEST","created":"2018-08-13T15:49:38","order_number":"8973946876","type":"VP","payment_method":"CC","risk_score":0.0,"amount":5.00,"custom":{"ref1":"","ref2":"","ref3":"","ref4":"","ref5":""},"card":{"card_type":"VI","address_match":0,"postal_result":0,"avs_result":"0","cvd_result":"1","cavv_result":"","avs":{"id":"U","message":"Address information is unavailable.","processed":false}}}'
      )
    )
  end

  def failed_void_response
    Bambora::API::ErrorResponse.new(
      JSON.parse('{"code":314,"category":3,"message":"Missing or invalid payment information - Please validate all required payment information.","reference":"","details":[{"field":"adjId","message":"Invalid adjustment id"}]}')
    )
  end
end
