/**
 * Centralized billing utilities for SplitSub frontend
 * Consolidates formatting, badge logic, and status calculations
 */

// ========================================
// FORMATTING UTILITIES
// ========================================

/**
 * Format currency amount to USD
 * @param {number} amount - The amount to format
 * @returns {string} Formatted currency string
 */
export function formatCurrency(amount) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
}

/**
 * Format date to readable format (Month Day, Year)
 * @param {string|Date} dateString - The date to format
 * @returns {string} Formatted date string
 */
export function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

/**
 * Format date and time to readable format
 * @param {string|Date} dateString - The date/time to format
 * @returns {string} Formatted date/time string
 */
export function formatDateTime(dateString) {
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

// ========================================
// BADGE VARIANT LOGIC
// ========================================

/**
 * Get badge variant for billing cycle frequency
 * @param {string} cycle - The billing cycle (monthly, quarterly, yearly, etc.)
 * @returns {string} Badge variant
 */
export function getBillingCycleBadgeVariant(cycle) {
  switch (cycle) {
    case "daily":
      return "outline";
    case "weekly":
      return "secondary";
    case "monthly":
      return "default";
    case "quarterly":
      return "secondary";
    case "yearly":
      return "outline";
    default:
      return "default";
  }
}

/**
 * Get badge variant for payment status
 * @param {string} status - The payment status
 * @returns {string} Badge variant
 */
export function getPaymentStatusBadgeVariant(status) {
  switch (status) {
    case "confirmed":
    case "paid":
      return "default";
    case "pending":
    case "partial":
      return "secondary";
    case "rejected":
    case "unpaid":
      return "destructive";
    default:
      return "outline";
  }
}

/**
 * Get badge variant for project status
 * @param {Object} project - Project object with status properties
 * @returns {string} Badge variant
 */
export function getProjectStatusBadgeVariant(project) {
  if (!project.active) return "destructive";
  if (project.expiring_soon) return "warning";
  return "success";
}

/**
 * Get badge variant for invitation status
 * @param {string} status - The invitation status
 * @returns {string} Badge variant
 */
export function getInvitationStatusBadgeVariant(status) {
  switch (status) {
    case "accepted":
      return "default";
    case "pending":
      return "secondary";
    case "declined":
    case "expired":
      return "destructive";
    default:
      return "outline";
  }
}

// ========================================
// STATUS CALCULATION HELPERS
// ========================================

/**
 * Get project status text
 * @param {Object} project - Project object
 * @returns {string} Status text
 */
export function getProjectStatusText(project) {
  if (!project.active) return "Expired";
  if (project.expiring_soon)
    return `Expires in ${project.days_until_renewal} days`;
  return "Active";
}

/**
 * Get billing cycle status icon component name
 * @param {Object} cycle - Billing cycle object
 * @returns {string} Icon component name
 */
export function getBillingCycleStatusIcon(cycle) {
  if (cycle.fully_paid) return "CheckCircle";
  if (cycle.overdue) return "AlertCircle";
  return "Clock";
}

/**
 * Get billing cycle status color class
 * @param {Object} cycle - Billing cycle object
 * @returns {string} CSS color class
 */
export function getBillingCycleStatusColor(cycle) {
  if (cycle.fully_paid) return "text-green-600";
  if (cycle.overdue) return "text-red-600";
  return "text-yellow-600";
}

/**
 * Get payment status icon component name
 * @param {string} status - Payment status
 * @returns {string} Icon component name
 */
export function getPaymentStatusIcon(status) {
  switch (status) {
    case "confirmed":
      return "CheckCircle";
    case "rejected":
      return "XCircle";
    case "pending":
      return "Clock";
    default:
      return "AlertCircle";
  }
}

// ========================================
// DATE/TIME CALCULATIONS
// ========================================

/**
 * Calculate days until due date
 * @param {string|Date} dueDate - The due date
 * @returns {number} Days until due (negative if overdue)
 */
export function calculateDaysUntilDue(dueDate) {
  const today = new Date();
  const due = new Date(dueDate);
  const diffTime = due - today;
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

/**
 * Check if a billing cycle is overdue
 * @param {Object} cycle - Billing cycle object
 * @returns {boolean} True if overdue
 */
export function isBillingCycleOverdue(cycle) {
  return cycle.days_until_due < 0;
}

/**
 * Check if a billing cycle is due soon
 * @param {Object} cycle - Billing cycle object
 * @param {number} dueSoonDays - Number of days to consider "due soon" (default: 7)
 * @returns {boolean} True if due soon
 */
export function isBillingCycleDueSoon(cycle, dueSoonDays = 7) {
  return cycle.days_until_due >= 0 && cycle.days_until_due <= dueSoonDays;
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
 * Calculate cost per member
 * @param {number} totalCost - Total project cost
 * @param {number} memberCount - Number of members
 * @returns {number} Cost per member
 */
export function calculateCostPerMember(totalCost, memberCount) {
  if (memberCount <= 0) return totalCost;
  return totalCost / memberCount;
}

// ========================================
// BILLING FREQUENCY HELPERS
// ========================================

/**
 * Get display name for billing frequency
 * @param {string} frequency - The billing frequency
 * @returns {string} Display name
 */
export function getBillingFrequencyDisplay(frequency) {
  switch (frequency) {
    case "daily":
      return "Daily";
    case "weekly":
      return "Weekly";
    case "monthly":
      return "Monthly";
    case "quarterly":
      return "Quarterly";
    case "yearly":
      return "Yearly";
    default:
      return frequency.charAt(0).toUpperCase() + frequency.slice(1);
  }
}

/**
 * Get billing frequency period in days
 * @param {string} frequency - The billing frequency
 * @returns {number} Number of days in the period
 */
export function getBillingFrequencyDays(frequency) {
  switch (frequency) {
    case "daily":
      return 1;
    case "weekly":
      return 7;
    case "monthly":
      return 30; // Approximate
    case "quarterly":
      return 90; // Approximate
    case "yearly":
      return 365; // Approximate
    default:
      return 30; // Default to monthly
  }
} 