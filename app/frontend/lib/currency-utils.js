/**
 * Currency utilities for SplitMySub frontend
 * Provides currency formatting, conversion, and display helpers
 */

// ISO 4217 currency codes with their display information
export const SUPPORTED_CURRENCIES = {
  'USD': { name: 'US Dollar', symbol: '$', locale: 'en-US' },
  'EUR': { name: 'Euro', symbol: '€', locale: 'en-GB' },
  'GBP': { name: 'British Pound', symbol: '£', locale: 'en-GB' },
  'CAD': { name: 'Canadian Dollar', symbol: 'C$', locale: 'en-CA' },
  'AUD': { name: 'Australian Dollar', symbol: 'A$', locale: 'en-AU' },
  'JPY': { name: 'Japanese Yen', symbol: '¥', locale: 'ja-JP' },
  'CHF': { name: 'Swiss Franc', symbol: 'CHF', locale: 'de-CH' },
  'CNY': { name: 'Chinese Yuan', symbol: '¥', locale: 'zh-CN' },
  'INR': { name: 'Indian Rupee', symbol: '₹', locale: 'en-IN' },
  'BRL': { name: 'Brazilian Real', symbol: 'R$', locale: 'pt-BR' },
  'MXN': { name: 'Mexican Peso', symbol: '$', locale: 'es-MX' },
  'KRW': { name: 'South Korean Won', symbol: '₩', locale: 'ko-KR' },
  'SGD': { name: 'Singapore Dollar', symbol: 'S$', locale: 'en-SG' },
  'HKD': { name: 'Hong Kong Dollar', symbol: 'HK$', locale: 'en-HK' },
  'NZD': { name: 'New Zealand Dollar', symbol: 'NZ$', locale: 'en-NZ' },
  'SEK': { name: 'Swedish Krona', symbol: 'kr', locale: 'sv-SE' },
  'NOK': { name: 'Norwegian Krone', symbol: 'kr', locale: 'nb-NO' },
  'DKK': { name: 'Danish Krone', symbol: 'kr', locale: 'da-DK' },
  'PLN': { name: 'Polish Złoty', symbol: 'zł', locale: 'pl-PL' },
  'CZK': { name: 'Czech Koruna', symbol: 'Kč', locale: 'cs-CZ' },
  'HUF': { name: 'Hungarian Forint', symbol: 'Ft', locale: 'hu-HU' },
  'BGN': { name: 'Bulgarian Lev', symbol: 'лв', locale: 'bg-BG' },
  'RON': { name: 'Romanian Leu', symbol: 'lei', locale: 'ro-RO' },
  'HRK': { name: 'Croatian Kuna', symbol: 'kn', locale: 'hr-HR' },
  'RUB': { name: 'Russian Ruble', symbol: '₽', locale: 'ru-RU' },
  'TRY': { name: 'Turkish Lira', symbol: '₺', locale: 'tr-TR' },
  'ZAR': { name: 'South African Rand', symbol: 'R', locale: 'en-ZA' },
  'THB': { name: 'Thai Baht', symbol: '฿', locale: 'th-TH' },
  'MYR': { name: 'Malaysian Ringgit', symbol: 'RM', locale: 'ms-MY' },
  'IDR': { name: 'Indonesian Rupiah', symbol: 'Rp', locale: 'id-ID' },
  'PHP': { name: 'Philippine Peso', symbol: '₱', locale: 'en-PH' },
  'VND': { name: 'Vietnamese Dong', symbol: '₫', locale: 'vi-VN' }
};

// Currencies that typically don't use decimal places
const NO_DECIMAL_CURRENCIES = ['JPY', 'KRW', 'VND', 'IDR', 'HUF', 'CLP', 'PYG', 'RWF', 'UGX', 'VUV', 'XAF', 'XOF', 'XPF'];

/**
 * Format currency amount using the browser's Intl.NumberFormat
 * @param {number} amount - The amount to format
 * @param {string} currencyCode - ISO 4217 currency code (e.g., 'USD', 'EUR')
 * @param {object} options - Additional formatting options
 * @returns {string} Formatted currency string
 */
export function formatCurrency(amount, currencyCode = 'USD', options = {}) {
  if (amount === null || amount === undefined) {
    return formatCurrency(0, currencyCode, options);
  }

  const currency = SUPPORTED_CURRENCIES[currencyCode?.toUpperCase()];
  if (!currency) {
    console.warn(`Unsupported currency: ${currencyCode}, falling back to USD`);
    return formatCurrency(amount, 'USD', options);
  }

  const locale = currency.locale;
  const useDecimals = !NO_DECIMAL_CURRENCIES.includes(currencyCode.toUpperCase());

  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currencyCode.toUpperCase(),
      minimumFractionDigits: useDecimals ? 2 : 0,
      maximumFractionDigits: useDecimals ? 2 : 0,
      ...options
    }).format(amount);
  } catch (error) {
    console.warn(`Error formatting currency ${currencyCode}:`, error);
    // Fallback to simple formatting
    const symbol = currency.symbol || '$';
    const formattedAmount = useDecimals ? amount.toFixed(2) : Math.round(amount).toString();
    return `${symbol}${formattedAmount}`;
  }
}

/**
 * Get currency symbol for a currency code
 * @param {string} currencyCode - ISO 4217 currency code
 * @returns {string} Currency symbol
 */
export function getCurrencySymbol(currencyCode) {
  const currency = SUPPORTED_CURRENCIES[currencyCode?.toUpperCase()];
  return currency?.symbol || '$';
}

/**
 * Get currency name for a currency code
 * @param {string} currencyCode - ISO 4217 currency code
 * @returns {string} Currency name
 */
export function getCurrencyName(currencyCode) {
  const currency = SUPPORTED_CURRENCIES[currencyCode?.toUpperCase()];
  return currency?.name || 'US Dollar';
}

/**
 * Get locale for a currency code
 * @param {string} currencyCode - ISO 4217 currency code
 * @returns {string} Locale string
 */
export function getCurrencyLocale(currencyCode) {
  const currency = SUPPORTED_CURRENCIES[currencyCode?.toUpperCase()];
  return currency?.locale || 'en-US';
}

/**
 * Check if a currency code is supported
 * @param {string} currencyCode - ISO 4217 currency code
 * @returns {boolean} True if supported
 */
export function isSupportedCurrency(currencyCode) {
  return SUPPORTED_CURRENCIES.hasOwnProperty(currencyCode?.toUpperCase());
}

/**
 * Get all supported currencies as an array of objects
 * @returns {Array} Array of currency objects with code, name, and symbol
 */
export function getSupportedCurrencies() {
  return Object.entries(SUPPORTED_CURRENCIES).map(([code, info]) => ({
    code,
    name: info.name,
    symbol: info.symbol,
    locale: info.locale,
    displayName: `${info.name} (${code})`
  }));
}

/**
 * Get currency options for select dropdowns
 * @returns {Array} Array of [displayName, code] pairs suitable for select options
 */
export function getCurrencyOptionsForSelect() {
  return getSupportedCurrencies()
    .map(currency => [currency.displayName, currency.code])
    .sort((a, b) => a[0].localeCompare(b[0]));
}

/**
 * Format currency with compact notation for large amounts
 * @param {number} amount - The amount to format
 * @param {string} currencyCode - ISO 4217 currency code
 * @returns {string} Formatted currency string with compact notation
 */
export function formatCurrencyCompact(amount, currencyCode = 'USD') {
  return formatCurrency(amount, currencyCode, {
    notation: 'compact',
    compactDisplay: 'short'
  });
}

/**
 * Parse a currency string and extract the numeric value
 * @param {string} currencyString - Formatted currency string
 * @param {string} currencyCode - ISO 4217 currency code for context
 * @returns {number|null} Parsed numeric value or null if parsing fails
 */
export function parseCurrency(currencyString, currencyCode = 'USD') {
  if (!currencyString || typeof currencyString !== 'string') {
    return null;
  }

  // Remove currency symbols and non-numeric characters except decimal point and minus
  const cleaned = currencyString.replace(/[^\d.-]/g, '');
  const parsed = parseFloat(cleaned);

  return isNaN(parsed) ? null : parsed;
}

/**
 * Get the default currency based on user's locale
 * @returns {string} Currency code
 */
export function getDefaultCurrency() {
  try {
    const locale = navigator.language || 'en-US';

    // Common locale to currency mappings
    const localeToCurrency = {
      'en-US': 'USD',
      'en-CA': 'CAD',
      'en-GB': 'GBP',
      'en-AU': 'AUD',
      'en-NZ': 'NZD',
      'en-ZA': 'ZAR',
      'en-IN': 'INR',
      'en-SG': 'SGD',
      'en-HK': 'HKD',
      'en-PH': 'PHP',
      'de': 'EUR',
      'de-DE': 'EUR',
      'de-AT': 'EUR',
      'de-CH': 'CHF',
      'fr': 'EUR',
      'fr-FR': 'EUR',
      'fr-CA': 'CAD',
      'fr-CH': 'CHF',
      'es': 'EUR',
      'es-ES': 'EUR',
      'es-MX': 'MXN',
      'it': 'EUR',
      'it-IT': 'EUR',
      'nl': 'EUR',
      'nl-NL': 'EUR',
      'pt': 'EUR',
      'pt-PT': 'EUR',
      'pt-BR': 'BRL',
      'ja': 'JPY',
      'ja-JP': 'JPY',
      'ko': 'KRW',
      'ko-KR': 'KRW',
      'zh': 'CNY',
      'zh-CN': 'CNY',
      'zh-HK': 'HKD',
      'zh-TW': 'TWD',
      'ru': 'RUB',
      'ru-RU': 'RUB',
      'tr': 'TRY',
      'tr-TR': 'TRY',
      'th': 'THB',
      'th-TH': 'THB',
      'vi': 'VND',
      'vi-VN': 'VND',
      'id': 'IDR',
      'id-ID': 'IDR',
      'ms': 'MYR',
      'ms-MY': 'MYR',
      'sv': 'SEK',
      'sv-SE': 'SEK',
      'no': 'NOK',
      'nb-NO': 'NOK',
      'da': 'DKK',
      'da-DK': 'DKK',
      'pl': 'PLN',
      'pl-PL': 'PLN',
      'cs': 'CZK',
      'cs-CZ': 'CZK',
      'hu': 'HUF',
      'hu-HU': 'HUF',
      'bg': 'BGN',
      'bg-BG': 'BGN',
      'ro': 'RON',
      'ro-RO': 'RON',
      'hr': 'HRK',
      'hr-HR': 'HRK'
    };

    return localeToCurrency[locale] || localeToCurrency[locale.split('-')[0]] || 'USD';
  } catch (error) {
    console.warn('Error detecting default currency:', error);
    return 'USD';
  }
}

/**
 * Format a range of currency amounts
 * @param {number} minAmount - Minimum amount
 * @param {number} maxAmount - Maximum amount  
 * @param {string} currencyCode - ISO 4217 currency code
 * @returns {string} Formatted currency range
 */
export function formatCurrencyRange(minAmount, maxAmount, currencyCode = 'USD') {
  if (minAmount === maxAmount) {
    return formatCurrency(minAmount, currencyCode);
  }

  return `${formatCurrency(minAmount, currencyCode)} - ${formatCurrency(maxAmount, currencyCode)}`;
}

// Export default formatCurrency for backward compatibility
export default formatCurrency; 