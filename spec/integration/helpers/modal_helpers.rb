def within_modal(timeout = 10, &block)
  modal_selector = "#facebox"
  page.should have_selector(modal_selector)
  within(modal_selector, &block)
end