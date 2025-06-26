module CurrencySupport
  extend ActiveSupport::Concern

  # ISO 4217 currency codes with their display information
  SUPPORTED_CURRENCIES = {
    "USD" => { name: "US Dollar", symbol: "$", locale: "en-US" },
    "EUR" => { name: "Euro", symbol: "\u20AC", locale: "en-GB" },
    "GBP" => { name: "British Pound", symbol: "\u00A3", locale: "en-GB" },
    "CAD" => { name: "Canadian Dollar", symbol: "C$", locale: "en-CA" },
    "AUD" => { name: "Australian Dollar", symbol: "A$", locale: "en-AU" },
    "JPY" => { name: "Japanese Yen", symbol: "\u00A5", locale: "ja-JP" },
    "CHF" => { name: "Swiss Franc", symbol: "CHF", locale: "de-CH" },
    "CNY" => { name: "Chinese Yuan", symbol: "\u00A5", locale: "zh-CN" },
    "INR" => { name: "Indian Rupee", symbol: "\u20B9", locale: "en-IN" },
    "BRL" => { name: "Brazilian Real", symbol: "R$", locale: "pt-BR" },
    "MXN" => { name: "Mexican Peso", symbol: "$", locale: "es-MX" },
    "KRW" => { name: "South Korean Won", symbol: "\u20A9", locale: "ko-KR" },
    "SGD" => { name: "Singapore Dollar", symbol: "S$", locale: "en-SG" },
    "HKD" => { name: "Hong Kong Dollar", symbol: "HK$", locale: "en-HK" },
    "NZD" => { name: "New Zealand Dollar", symbol: "NZ$", locale: "en-NZ" },
    "SEK" => { name: "Swedish Krona", symbol: "kr", locale: "sv-SE" },
    "NOK" => { name: "Norwegian Krone", symbol: "kr", locale: "nb-NO" },
    "DKK" => { name: "Danish Krone", symbol: "kr", locale: "da-DK" },
    "PLN" => { name: "Polish Z\u0142oty", symbol: "z\u0142", locale: "pl-PL" },
    "CZK" => { name: "Czech Koruna", symbol: "K\u010D", locale: "cs-CZ" },
    "HUF" => { name: "Hungarian Forint", symbol: "Ft", locale: "hu-HU" },
    "BGN" => { name: "Bulgarian Lev", symbol: "\u043B\u0432", locale: "bg-BG" },
    "RON" => { name: "Romanian Leu", symbol: "lei", locale: "ro-RO" },
    "HRK" => { name: "Croatian Kuna", symbol: "kn", locale: "hr-HR" },
    "RUB" => { name: "Russian Ruble", symbol: "\u20BD", locale: "ru-RU" },
    "TRY" => { name: "Turkish Lira", symbol: "\u20BA", locale: "tr-TR" },
    "ZAR" => { name: "South African Rand", symbol: "R", locale: "en-ZA" },
    "THB" => { name: "Thai Baht", symbol: "\u0E3F", locale: "th-TH" },
    "MYR" => { name: "Malaysian Ringgit", symbol: "RM", locale: "ms-MY" },
    "IDR" => { name: "Indonesian Rupiah", symbol: "Rp", locale: "id-ID" },
    "PHP" => { name: "Philippine Peso", symbol: "\u20B1", locale: "en-PH" },
    "VND" => { name: "Vietnamese Dong", symbol: "\u20AB", locale: "vi-VN" }
  }.freeze

  class_methods do
    def supported_currencies
      SUPPORTED_CURRENCIES
    end

    def valid_currency?(code)
      SUPPORTED_CURRENCIES.key?(code&.upcase)
    end

    def currency_name(code)
      SUPPORTED_CURRENCIES.dig(code&.upcase, :name)
    end

    def currency_symbol(code)
      SUPPORTED_CURRENCIES.dig(code&.upcase, :symbol)
    end

    def currency_locale(code)
      SUPPORTED_CURRENCIES.dig(code&.upcase, :locale)
    end

    def currency_options_for_select
      SUPPORTED_CURRENCIES.map do |code, info|
        [ "#{info[:name]} (#{code})", code ]
      end.sort_by(&:first)
    end
  end

  included do
    validates :currency, inclusion: { in: SUPPORTED_CURRENCIES.keys }, if: -> { respond_to?(:currency) }
    validates :preferred_currency, inclusion: { in: SUPPORTED_CURRENCIES.keys }, if: -> { respond_to?(:preferred_currency) }
  end

  def currency_name
    self.class.currency_name(currency)
  end

  def currency_symbol
    self.class.currency_symbol(currency)
  end

  def currency_locale
    self.class.currency_locale(currency)
  end

  def format_amount(amount)
    return "0.00" if amount.nil?

    locale = currency_locale || "en-US"
    currency_code = currency || "USD"

    # Use JavaScript's Intl.NumberFormat equivalent in Ruby
    # For server-side rendering, we'll use a simple format
    symbol = currency_symbol || "$"
    formatted_amount = sprintf("%.2f", amount)

    case currency_code
    when "JPY", "KRW", "VND", "IDR"
      # These currencies typically don't use decimal places
      "#{symbol}#{amount.to_i}"
    else
      "#{symbol}#{formatted_amount}"
    end
  end
end
