# frozen_string_literal: true

# This is just a thin wrapper around the API's data structure which is a little
# heterogeneous. There's one Inventory Record for the Form's overall capacity
# (called 'quantity'); plus one for each ticket level's quantity, but only when
# there is more than just the one default ticket level; and then one record for
# each date/time. The 'path', 'name', and 'key' fields tell you what you're
# looking at. 'sold' and 'quantity' are the numbers.
#
#   path: "tickets",       name: "tickets"                            # overall capacity for the whole Form
#   path: "tickets.adult", name: "General Admission"                  # example ticket-level capacity (my default ticket level)
#   path: "tickets.standingRoomOnly", name: "Standing Room Only"      # example ticket-level capacity for a second level
#
#   path: "tickets",       name: "tickets-2022-07-22 20:00"           # sales data for a performance
#   path: "tickets.adult", name: "General Admission-2022-07-22 20:00" # sales data for one ticket level of that performance
#
# The 'key' field is the part of the 'name' field after the hyphen and
# identifies the individual performance/showing/etc. and indicates that you're
# looking at its sales data. For my data from Ticketspice, the key is always the
# same datetime string as the part after the hyphen. There is no 'key' field on
# the other records.
#
# n.b. the 'quantity' fields change retrospectively when you adjust in the web
# interface. So be careful making assumptions about old shows if you increase
# capacity during a run.
class WebconnexAPI::InventoryRecord < OpenStruct
  # TODO OpenStruct is bad for bugs and security read its rdoc.

  def self.all_by_form_id(form_id)
    # TODO: this fails for unpublished forms (see fixture 481580)
    json = WebconnexAPI.get_request("/forms/#{form_id}/inventory")
    JSON.parse(json, object_class: self).data
  end

  def event_time
    # TODO: These fields don't have a TZ on them. Works great when this machine
    # is in the event TZ... =D
    # We could allow the user to configure this class with a TZ name to assume,
    # like "America/New_York"
    if event_has_date_but_no_time?
      raise "This Inventory Record does not have a time " +
            "(name: #{name.inspect}, key: #{key.inspect})"
    end

    @event_time ||= Time.strptime(key, "%Y-%m-%d %H:%M")
  end

  def event_date
    if event_has_date_but_no_time?
      Time.strptime(key, "%Y-%m-%d").to_date
    else
      event_time.to_date
    end
  end

  def upcoming?
    if event_has_date_but_no_time?
      event_date >= Date.today
    else
      event_time >= Time.now
    end
  end

  def past?
    !upcoming?
  end

  # When you put a show on sale, sell tickets, then later move/refund all the
  # orders and hide the show using an Action, you'll still get an Inventory
  # Record back showing zero tickets sold. This doesn't happen for shows that
  # never sell a ticket. So, checking for this is one way to fix up junk data
  # without fully implementing the Actions' logic. (And keeping track of what
  # that logic was as of the time of each show.)
  def none_sold?
    sold.zero?
  end

  def event_has_date_but_no_time?
    key =~ /^\d\d\d\d-\d\d-\d\d$/
  end

  def single_performance_sales_record?
    !key.nil?
  end

  def single_performance_total_sales_record?
    single_performance_sales_record? && path == "tickets"
  end

  def single_performance_ticket_level_sales_record?
    single_performance_sales_record? && path.starts_with?("tickets.")
  end
end
