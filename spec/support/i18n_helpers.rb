def store_translations(locale, translations, &block)
  I18n.backend.store_translations locale, translations
  yield
ensure
  I18n.reload!
  I18n.backend.send :init_translations
end
