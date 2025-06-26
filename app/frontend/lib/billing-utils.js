/**
 * Centralized billing utilities for SplitMySub frontend
 * Consolidates formatting, badge logic, and status calculations
 */

import { formatCurrency as formatCurrencyUtil, getCurrencySymbol, isValidCurrency } from './currency-utils.js';

// ========================================
// FORMATTING UTILITIES
// ========================================

/**
 * Format currency amount with dynamic currency support
 * @param {number} amount - The amount to format
 * @param {string} currency - Currency code (e.g., 'USD', 'EUR')
 * @returns {string} Formatted currency string
 */
export function formatCurrency(amount, currency) {
  return formatCurrencyUtil(amount, currency);
}

/**
 * Legacy formatCurrency function for backward compatibility
 * @deprecated Use formatCurrency(amount, currency) instead
 * @param {number} amount - The amount to format
 * @returns {string} Formatted currency string in USD
 */
export function formatCurrencyUSD(amount) {
  return formatCurrency(amount, 'USD');
}

/**
 * Format date to a readable string
 * @param {string|Date} date - Date to format
 * @returns {string} Formatted date string
 */
export function formatDate(date) {
  if (!date) return '';

  const dateObj = date instanceof Date ? date : new Date(date);
  return dateObj.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

/**
 * Format datetime to a readable string
 * @param {string|Date} datetime - DateTime to format
 * @returns {string} Formatted datetime string
 */
export function formatDateTime(datetime) {
  if (!datetime) return '';

  const dateObj = datetime instanceof Date ? datetime : new Date(datetime);
  return dateObj.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Format time to a readable string
 * @param {string|Date} time - Time to format
 * @returns {string} Formatted time string
 */
export function formatTime(time) {
  if (!time) return '';

  const dateObj = time instanceof Date ? time : new Date(time);
  return dateObj.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

// ========================================
// BADGE UTILITIES
// ========================================

/**
 * Get badge variant for payment status
 * @param {string} status - Payment status
 * @returns {string} Badge variant class
 */
export function getPaymentStatusBadgeVariant(status) {
  const variants = {
    'confirmed': 'default',
    'paid': 'default',
    'pending': 'secondary',
    'partial': 'secondary',
    'rejected': 'destructive',
    'unpaid': 'destructive'
  };

  return variants[status] || 'outline';
}

/**
 * Get badge variant for billing cycle status
 * @param {string} status - Billing cycle status
 * @returns {string} Badge variant class
 */
export function getBillingCycleStatusBadgeVariant(status) {
  const variants = {
    'paid': 'default',
    'partial': 'secondary',
    'upcoming': 'outline',
    'due_soon': 'secondary',
    'overdue': 'destructive',
    'unpaid': 'destructive'
  };

  return variants[status] || 'outline';
}

/**
 * Get badge variant for invitation status
 * @param {string} status - Invitation status
 * @returns {string} Badge variant class
 */
export function getInvitationStatusBadgeVariant(status) {
  const variants = {
    'accepted': 'default',
    'pending': 'secondary',
    'declined': 'destructive',
    'expired': 'destructive'
  };

  return variants[status] || 'outline';
}

/**
 * Get badge variant for project status
 * @param {string} status - Project status
 * @returns {string} Badge variant class
 */
export function getProjectStatusBadgeVariant(status) {
  const variants = {
    'active': 'default',
    'expired': 'destructive',
    'expiring_soon': 'secondary'
  };

  return variants[status] || 'outline';
}

// ========================================
// STATUS CALCULATIONS
// ========================================

/**
 * Calculate billing cycle status based on dates and payment info
 * @param {Object} billingCycle - Billing cycle object
 * @returns {string} Status string
 */
export function calculateBillingCycleStatus(billingCycle) {
  if (!billingCycle) return 'unknown';

  const { due_date, payment_status, total_paid, total_amount } = billingCycle;
  const today = new Date();
  const dueDate = new Date(due_date);
  const daysUntilDue = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

  // Check payment status first
  if (payment_status === 'paid' || (total_paid >= total_amount)) {
    return 'paid';
  }

  if (payment_status === 'partial' || (total_paid > 0 && total_paid < total_amount)) {
    return 'partial';
  }

  // Check date-based status
  if (daysUntilDue < 0) {
    return 'overdue';
  }

  if (daysUntilDue <= 7) {
    return 'due_soon';
  }

  if (daysUntilDue > 7) {
    return 'upcoming';
  }

  return 'unpaid';
}

/**
 * Calculate project status based on renewal date
 * @param {Object} project - Project object
 * @returns {string} Status string
 */
export function calculateProjectStatus(project) {
  if (!project || !project.renewal_date) return 'unknown';

  const today = new Date();
  const renewalDate = new Date(project.renewal_date);
  const daysUntilRenewal = Math.ceil((renewalDate - today) / (1000 * 60 * 60 * 24));

  if (daysUntilRenewal < 0) {
    return 'expired';
  }

  if (daysUntilRenewal <= 7) {
    return 'expiring_soon';
  }

  return 'active';
}

/**
 * Get human-readable status label
 * @param {string} status - Status code
 * @param {string} type - Type of status (payment, billing_cycle, project, invitation)
 * @returns {string} Human-readable label
 */
export function getStatusLabel(status, type = 'payment') {
  const labels = {
    payment: {
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'rejected': 'Rejected',
      'paid': 'Paid',
      'unpaid': 'Unpaid',
      'partial': 'Partial'
    },
    billing_cycle: {
      'upcoming': 'Upcoming',
      'due_soon': 'Due Soon',
      'overdue': 'Overdue',
      'paid': 'Paid',
      'partial': 'Partial',
      'unpaid': 'Unpaid'
    },
    project: {
      'active': 'Active',
      'expired': 'Expired',
      'expiring_soon': 'Expiring Soon'
    },
    invitation: {
      'pending': 'Pending',
      'accepted': 'Accepted',
      'declined': 'Declined',
      'expired': 'Expired'
    }
  };

  return labels[type]?.[status] || status.charAt(0).toUpperCase() + status.slice(1);
}

// ========================================
// PROGRESS CALCULATIONS
// ========================================

/**
 * Calculate payment progress percentage
 * @param {number} totalPaid - Amount paid
 * @param {number} totalAmount - Total amount due
 * @returns {number} Progress percentage (0-100)
 */
export function calculatePaymentProgress(totalPaid, totalAmount) {
  if (totalAmount <= 0) return 0;
  return Math.min(100, Math.max(0, (totalPaid / totalAmount) * 100));
}

/**
 * Calculate days remaining until due date
 * @param {string|Date} dueDate - Due date
 * @returns {number} Days remaining (negative if overdue)
 */
export function calculateDaysRemaining(dueDate) {
  if (!dueDate) return 0;

  const today = new Date();
  const due = new Date(dueDate);
  return Math.ceil((due - today) / (1000 * 60 * 60 * 24));
}

/**
 * Check if a date is overdue
 * @param {string|Date} dueDate - Due date to check
 * @returns {boolean} True if overdue
 */
export function isOverdue(dueDate) {
  return calculateDaysRemaining(dueDate) < 0;
}

/**
 * Check if a date is due soon (within specified days)
 * @param {string|Date} dueDate - Due date to check
 * @param {number} threshold - Days threshold (default: 7)
 * @returns {boolean} True if due soon
 */
export function isDueSoon(dueDate, threshold = 7) {
  const daysRemaining = calculateDaysRemaining(dueDate);
  return daysRemaining >= 0 && daysRemaining <= threshold;
}

// ========================================
// AMOUNT CALCULATIONS
// ========================================

/**
 * Calculate per-member amount
 * @param {number} totalAmount - Total amount
 * @param {number} memberCount - Number of members
 * @returns {number} Amount per member
 */
export function calculatePerMemberAmount(totalAmount, memberCount) {
  if (memberCount <= 0) return 0;
  return totalAmount / memberCount;
}

/**
 * Calculate total amount from per-member amount
 * @param {number} perMemberAmount - Amount per member
 * @param {number} memberCount - Number of members
 * @returns {number} Total amount
 */
export function calculateTotalAmount(perMemberAmount, memberCount) {
  return perMemberAmount * memberCount;
}

/**
 * Round amount to appropriate decimal places based on currency
 * @param {number} amount - Amount to round
 * @param {string} currency - Currency code
 * @returns {number} Rounded amount
 */
export function roundAmount(amount, currency = 'USD') {
  // Currencies that don't use decimals
  const noDecimalCurrencies = ['JPY', 'KRW', 'VND', 'IDR'];

  if (noDecimalCurrencies.includes(currency.toUpperCase())) {
    return Math.round(amount);
  }

  return Math.round(amount * 100) / 100;
}

// ========================================
// VALIDATION UTILITIES
// ========================================

/**
 * Validate amount input
 * @param {string|number} amount - Amount to validate
 * @returns {Object} Validation result with isValid and error properties
 */
export function validateAmount(amount) {
  const numAmount = parseFloat(amount);

  if (isNaN(numAmount)) {
    return { isValid: false, error: 'Amount must be a valid number' };
  }

  if (numAmount <= 0) {
    return { isValid: false, error: 'Amount must be greater than zero' };
  }

  if (numAmount > 999999.99) {
    return { isValid: false, error: 'Amount is too large' };
  }

  return { isValid: true, error: null };
}

/**
 * Validate date input
 * @param {string|Date} date - Date to validate
 * @param {boolean} allowPast - Whether to allow past dates
 * @returns {Object} Validation result with isValid and error properties
 */
export function validateDate(date, allowPast = false) {
  if (!date) {
    return { isValid: false, error: 'Date is required' };
  }

  const dateObj = date instanceof Date ? date : new Date(date);

  if (isNaN(dateObj.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (!allowPast && dateObj < new Date()) {
    return { isValid: false, error: 'Date cannot be in the past' };
  }

  return { isValid: true, error: null };
}

// ========================================
// SORTING UTILITIES
// ========================================

/**
 * Sort billing cycles by various criteria
 * @param {Array} cycles - Array of billing cycles
 * @param {string} sortBy - Sort criteria
 * @param {string} order - Sort order ('asc' or 'desc')
 * @returns {Array} Sorted array
 */
export function sortBillingCycles(cycles, sortBy = 'due_date', order = 'asc') {
  const sorted = [...cycles].sort((a, b) => {
    let aVal, bVal;

    switch (sortBy) {
      case 'due_date':
        aVal = new Date(a.due_date);
        bVal = new Date(b.due_date);
        break;
      case 'total_amount':
        aVal = a.total_amount;
        bVal = b.total_amount;
        break;
      case 'created_at':
        aVal = new Date(a.created_at);
        bVal = new Date(b.created_at);
        break;
      case 'status':
        aVal = calculateBillingCycleStatus(a);
        bVal = calculateBillingCycleStatus(b);
        break;
      default:
        aVal = a[sortBy];
        bVal = b[sortBy];
    }

    if (aVal < bVal) return order === 'asc' ? -1 : 1;
    if (aVal > bVal) return order === 'asc' ? 1 : -1;
    return 0;
  });

  return sorted;
}

// ========================================
// FILTERING UTILITIES
// ========================================

/**
 * Filter billing cycles by status
 * @param {Array} cycles - Array of billing cycles
 * @param {string|Array} status - Status or array of statuses to filter by
 * @returns {Array} Filtered array
 */
export function filterBillingCyclesByStatus(cycles, status) {
  if (!status || status === 'all') return cycles;

  const statusArray = Array.isArray(status) ? status : [status];

  return cycles.filter(cycle => {
    const cycleStatus = calculateBillingCycleStatus(cycle);
    return statusArray.includes(cycleStatus);
  });
}

/**
 * Filter billing cycles by date range
 * @param {Array} cycles - Array of billing cycles
 * @param {Date} startDate - Start date (optional)
 * @param {Date} endDate - End date (optional)
 * @returns {Array} Filtered array
 */
export function filterBillingCyclesByDateRange(cycles, startDate = null, endDate = null) {
  return cycles.filter(cycle => {
    const dueDate = new Date(cycle.due_date);

    if (startDate && dueDate < startDate) return false;
    if (endDate && dueDate > endDate) return false;

    return true;
  });
}

/**
 * Filter billing cycles by currency
 * @param {Array} cycles - Array of billing cycles
 * @param {string} currency - Currency code to filter by
 * @returns {Array} Filtered array
 */
export function filterBillingCyclesByCurrency(cycles, currency) {
  if (!currency) return cycles;

  return cycles.filter(cycle => cycle.currency === currency);
}

// ========================================
// CURRENCY UTILITIES
// ========================================

/**
 * Helper to get currency from nested objects (billing_cycle -> project -> currency)
 * @param {Object} obj - The object to search for currency
 * @returns {string} Currency code
 */
export function getCurrency(obj) {
  // If obj has currency directly
  if (obj?.currency) {
    return obj.currency;
  }

  // If obj has project with currency
  if (obj?.project?.currency) {
    return obj.project.currency;
  }

  // If obj is a billing_cycle, try to get from project
  if (obj?.project) {
    return obj.project.currency;
  }

  // If obj is a payment, try to get from billing_cycle -> project
  if (obj?.billing_cycle?.project?.currency) {
    return obj.billing_cycle.project.currency;
  }

  // Default to USD
  return 'USD';
}

/**
 * Convenience function to format currency with automatic currency detection
 * @param {number} amount - The amount to format
 * @param {Object} obj - Object to extract currency from
 * @returns {string} Formatted currency string
 */
export function formatCurrencyAuto(amount, obj) {
  const currency = getCurrency(obj);
  return formatCurrency(amount, currency);
}

// Export currency utilities for convenience
export { getCurrencySymbol, isValidCurrency };