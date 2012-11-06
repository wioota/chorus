def within_modal(timeout = 10, &block)
  modal_selector = "#facebox"
  wait_until(timeout) { page.has_selector?(modal_selector) }
  wait_for_ajax(timeout)
  within(modal_selector, &block)
  wait_for_ajax(timeout)
end