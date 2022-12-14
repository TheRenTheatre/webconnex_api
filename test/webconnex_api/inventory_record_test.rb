# frozen_string_literal: true

require 'test_helper'

class TestWebconnexAPIInventoryRecord < Minitest::Test
  def test_all_by_form_id_does_not_raise
    # plaintext
    # curl --http1.1 -X "GET" -is "https://api.webconnex.com/v2/public/forms/481603/inventory" -H "apiKey: ffff084aa7abee86fc0203e606faffff" -H "Accept: */*" -H "User-Agent: Ruby" -H "Host: api.webconnex.com" > test/fixtures/v2-public-forms-481603-inventory
    resp = fixture_path("v2-public-forms-481603-inventory");

    # In reality, Net::HTTP will gzip by default. FakeWeb doesn't support this. yet? lol
    # curl --http1.1 -X "GET" -is "https://api.webconnex.com/v2/public/forms/481603/inventory" -H "apiKey: ffff084aa7abee86fc0203e606faffff" -H "Accept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3" -H "Accept: */*" -H "User-Agent: Ruby" -H "Host: api.webconnex.com" > test/fixtures/v2-public-forms-481603-inventory.gzip

    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603/inventory", :response => resp)
    WebconnexAPI::InventoryRecord.all_by_form_id(481603)
  end

  def test_upcoming_and_past
    resp = fixture_path("v2-public-forms-481603")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603", :response => resp)
    resp = fixture_path("v2-public-forms-481603-inventory")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603/inventory", :response => resp)

    irs = WebconnexAPI::InventoryRecord.all_by_form_id(481603).select(&:single_performance_sales_record?)
    irs.each do |ir|
      refute_equal ir.upcoming?, ir.past
    end
  end
end
