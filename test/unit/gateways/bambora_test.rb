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

    assert_equal 'Approved', response.authorization
  end

  def test_failed_purchase
    Bambora::API::Payment.expects(:create).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_authorize
    Bambora::API::Payment.expects(:preauth).returns(successful_authorize_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'Approved', response.authorization
  end

  def test_failed_authorize
    Bambora::API::Payment.expects(:preauth).returns(failed_authorize_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_capture
    Bambora::API::Payment.expects(:preauth).returns(successful_authorize_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'Approved', response.authorization

    Bambora::API::Payment.expects(:complete).returns(successful_complete_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'Approved', response.authorization
  end

  def test_failed_capture
    Bambora::API::Payment.expects(:preauth).returns(failed_authorize_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code

    Bambora::API::Payment.expects(:complete).returns(failed_capture_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_successful_refund
  end

  def test_failed_refund
  end

  def test_successful_void
  end

  def test_failed_void
  end

  def test_successful_verify
  end

  def test_successful_verify_with_failed_void
  end

  def test_failed_verify
  end

  def test_scrub
    assert @gateway.supports_scrubbing?
    assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  end

  private

  def pre_scrubbed
    %q(
      Run the remote tests for this gateway, and then put the contents of transcript.log here.
    )
  end

  def post_scrubbed
    %q(
      Put the scrubbed contents of transcript.log here after implementing your scrubbing function.
      Things to scrub:
        - Credit card number
        - CVV
        - Sensitive authentication details
    )
  end

  def successful_purchase_response
    Response.new(true, 'Approved', params: {}, options: { authorization: 'Approved', test: true })
  end

  def failed_purchase_response
    Response.new(false, 'Decline', params: {}, options: { error_code: '217', test: true})
  end

  def successful_authorize_response
    Response.new(true, 'Approved', params: {}, options: { authorization: 'Approved', test: true })
  end

  def failed_authorize_response
    Response.new(false, 'Decline', params: {}, options: { error_code: '217', test: true})
  end

  def successful_capture_response
  end

  def failed_capture_response
  end

  def successful_refund_response
  end

  def failed_refund_response
  end

  def successful_void_response
  end

  def failed_void_response
  end
end
