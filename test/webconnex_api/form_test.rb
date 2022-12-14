# frozen_string_literal: true

require 'test_helper'

class TestWebconnexAPIForm < Minitest::Test
  # To grab a fixture in plaintext (set an ID)
  # curl --http1.1 -X "GET" -is "https://api.webconnex.com/v2/public/forms/$ID" -H "apiKey: $WEBCONNEX_API_KEY" -H "Accept: */*" -H "User-Agent: Ruby" -H "Host: api.webconnex.com" > test/fixtures/v2-public-forms-$ID
  #
  # Useful fixtures:
  # 481580 - unpublished, archived form with same name as a published one (Bullock and the Bandits)
  # 481581 - the published one
  # 481603 - one where we have inventory records fixtures as well (Lenox Ave)

  def test_find_does_not_raise
    resp = fixture_path("v2-public-forms-481581")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481580", :response => resp)
    WebconnexAPI::Form.find(481580)
  end

  def test_published_returns_false_when_published_path_is_missing
    resp = fixture_path("v2-public-forms-481580")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481580", :response => resp)
    form = WebconnexAPI::Form.find(481580)
    assert_nil form["publishedPath"]
    refute form.published?
  end

  def test_published_returns_true_when_published_path_is_present
    resp = fixture_path("v2-public-forms-481581")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481581", :response => resp)
    form = WebconnexAPI::Form.find(481581)
    refute_nil form["publishedPath"]
    assert form.published?
  end

  def test_inventory_records_accessor_returns_the_same_collection_as_a_direct_call
    resp = fixture_path("v2-public-forms-481603")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603", :response => resp)
    form = WebconnexAPI::Form.find(481603)

    resp = fixture_path("v2-public-forms-481603-inventory")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603/inventory", :response => resp)
    expected = WebconnexAPI::InventoryRecord.all_by_form_id(481603)
    assert_instance_of WebconnexAPI::InventoryRecord, expected.first
    assert_equal expected, form.inventory_records
  end

  def test_inventory_records_accessor_raises_when_unpublished
    resp = fixture_path("v2-public-forms-481580")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481580", :response => resp)
    form = WebconnexAPI::Form.find(481580)
    assert_raises do
      form.inventory_records
    end
  end

  def test_inventory_records_accessor_only_makes_api_request_once
    resp = fixture_path("v2-public-forms-481603")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603", :response => resp)
    form = WebconnexAPI::Form.find(481603)

    resp = fixture_path("v2-public-forms-481603-inventory")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603/inventory",
                         [{:response => resp}, {:exception => StandardError}])
    form.inventory_records
    form.inventory_records
  end

  def test_ticket_level_names
    resp = fixture_path("v2-public-forms-481603")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603", :response => resp)
    form = WebconnexAPI::Form.find(481603)
    assert_equal ["General Admission", "Standing Room Only"], form.ticket_level_names
  end

  def test_ticket_level_names_when_fields_arent_loaded
    resp = fixture_path("v2-public-forms-all")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms", :response => resp)
    forms = WebconnexAPI::Form.all

    form = forms.find { |f| f.id == 481603 }

    resp = fixture_path("v2-public-forms-481603")
    FakeWeb.register_uri(:get, "https://api.webconnex.com/v2/public/forms/481603", :response => resp)

    assert_equal ["General Admission", "Standing Room Only"], form.ticket_level_names
  end
end
