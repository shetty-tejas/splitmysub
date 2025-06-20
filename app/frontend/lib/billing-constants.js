/**
 * Centralized billing constants for SplitSub frontend
 * Contains status mappings, default values, and configuration constants
 */

// ========================================
// PAYMENT STATUS CONSTANTS
// ========================================

export const PAYMENT_STATUSES = {
  PENDING: "pending",
  CONFIRMED: "confirmed",
  REJECTED: "rejected",
  PAID: "paid",
  UNPAID: "unpaid",
  PARTIAL: "partial",
};

export const PAYMENT_STATUS_LABELS = {
  [PAYMENT_STATUSES.PENDING]: "Pending",
  [PAYMENT_STATUSES.CONFIRMED]: "Confirmed",
  [PAYMENT_STATUSES.REJECTED]: "Rejected",
  [PAYMENT_STATUSES.PAID]: "Paid",
  [PAYMENT_STATUSES.UNPAID]: "Unpaid",
  [PAYMENT_STATUSES.PARTIAL]: "Partial",
};

// ========================================
// BILLING CYCLE STATUS CONSTANTS
// ========================================

export const BILLING_CYCLE_STATUSES = {
  UPCOMING: "upcoming",
  DUE_SOON: "due_soon",
  OVERDUE: "overdue",
  PAID: "paid",
  PARTIAL: "partial",
  UNPAID: "unpaid",
};

export const BILLING_CYCLE_STATUS_LABELS = {
  [BILLING_CYCLE_STATUSES.UPCOMING]: "Upcoming",
  [BILLING_CYCLE_STATUSES.DUE_SOON]: "Due Soon",
  [BILLING_CYCLE_STATUSES.OVERDUE]: "Overdue",
  [BILLING_CYCLE_STATUSES.PAID]: "Paid",
  [BILLING_CYCLE_STATUSES.PARTIAL]: "Partial",
  [BILLING_CYCLE_STATUSES.UNPAID]: "Unpaid",
};

// ========================================
// BILLING FREQUENCY CONSTANTS
// ========================================

export const BILLING_FREQUENCIES = {
  DAILY: "daily",
  WEEKLY: "weekly",
  MONTHLY: "monthly",
  QUARTERLY: "quarterly",
  YEARLY: "yearly",
};

export const BILLING_FREQUENCY_LABELS = {
  [BILLING_FREQUENCIES.DAILY]: "Daily",
  [BILLING_FREQUENCIES.WEEKLY]: "Weekly",
  [BILLING_FREQUENCIES.MONTHLY]: "Monthly",
  [BILLING_FREQUENCIES.QUARTERLY]: "Quarterly",
  [BILLING_FREQUENCIES.YEARLY]: "Yearly",
};

export const BILLING_FREQUENCY_DAYS = {
  [BILLING_FREQUENCIES.DAILY]: 1,
  [BILLING_FREQUENCIES.WEEKLY]: 7,
  [BILLING_FREQUENCIES.MONTHLY]: 30,
  [BILLING_FREQUENCIES.QUARTERLY]: 90,
  [BILLING_FREQUENCIES.YEARLY]: 365,
};

// ========================================
// PROJECT STATUS CONSTANTS
// ========================================

export const PROJECT_STATUSES = {
  ACTIVE: "active",
  EXPIRED: "expired",
  EXPIRING_SOON: "expiring_soon",
};

export const PROJECT_STATUS_LABELS = {
  [PROJECT_STATUSES.ACTIVE]: "Active",
  [PROJECT_STATUSES.EXPIRED]: "Expired",
  [PROJECT_STATUSES.EXPIRING_SOON]: "Expiring Soon",
};

// ========================================
// INVITATION STATUS CONSTANTS
// ========================================

export const INVITATION_STATUSES = {
  PENDING: "pending",
  ACCEPTED: "accepted",
  DECLINED: "declined",
  EXPIRED: "expired",
};

export const INVITATION_STATUS_LABELS = {
  [INVITATION_STATUSES.PENDING]: "Pending",
  [INVITATION_STATUSES.ACCEPTED]: "Accepted",
  [INVITATION_STATUSES.DECLINED]: "Declined",
  [INVITATION_STATUSES.EXPIRED]: "Expired",
};

// ========================================
// BADGE VARIANT MAPPINGS
// ========================================

export const BADGE_VARIANTS = {
  DEFAULT: "default",
  SECONDARY: "secondary",
  DESTRUCTIVE: "destructive",
  OUTLINE: "outline",
  SUCCESS: "success",
  WARNING: "warning",
};

export const PAYMENT_STATUS_BADGE_VARIANTS = {
  [PAYMENT_STATUSES.CONFIRMED]: BADGE_VARIANTS.DEFAULT,
  [PAYMENT_STATUSES.PAID]: BADGE_VARIANTS.DEFAULT,
  [PAYMENT_STATUSES.PENDING]: BADGE_VARIANTS.SECONDARY,
  [PAYMENT_STATUSES.PARTIAL]: BADGE_VARIANTS.SECONDARY,
  [PAYMENT_STATUSES.REJECTED]: BADGE_VARIANTS.DESTRUCTIVE,
  [PAYMENT_STATUSES.UNPAID]: BADGE_VARIANTS.DESTRUCTIVE,
};

export const BILLING_FREQUENCY_BADGE_VARIANTS = {
  [BILLING_FREQUENCIES.DAILY]: BADGE_VARIANTS.OUTLINE,
  [BILLING_FREQUENCIES.WEEKLY]: BADGE_VARIANTS.SECONDARY,
  [BILLING_FREQUENCIES.MONTHLY]: BADGE_VARIANTS.DEFAULT,
  [BILLING_FREQUENCIES.QUARTERLY]: BADGE_VARIANTS.SECONDARY,
  [BILLING_FREQUENCIES.YEARLY]: BADGE_VARIANTS.OUTLINE,
};

export const INVITATION_STATUS_BADGE_VARIANTS = {
  [INVITATION_STATUSES.ACCEPTED]: BADGE_VARIANTS.DEFAULT,
  [INVITATION_STATUSES.PENDING]: BADGE_VARIANTS.SECONDARY,
  [INVITATION_STATUSES.DECLINED]: BADGE_VARIANTS.DESTRUCTIVE,
  [INVITATION_STATUSES.EXPIRED]: BADGE_VARIANTS.DESTRUCTIVE,
};

// ========================================
// DEFAULT VALUES (Configuration-driven)
// ========================================

// These should be replaced with values from BillingConfig when available
export const DEFAULT_VALUES = {
  DUE_SOON_DAYS: 7,
  GENERATION_MONTHS_AHEAD: 3,
  ARCHIVING_MONTHS_THRESHOLD: 6,
  REMINDER_DAYS_BEFORE: 7,
  DEFAULT_BILLING_FREQUENCY: BILLING_FREQUENCIES.MONTHLY,
  DEFAULT_PRIORITY: "medium",
};

// ========================================
// SORT OPTIONS
// ========================================

export const SORT_OPTIONS = {
  DUE_DATE_DESC: "due_date_desc",
  DUE_DATE_ASC: "due_date_asc",
  AMOUNT_DESC: "amount_desc",
  AMOUNT_ASC: "amount_asc",
  CREATED_DESC: "created_desc",
  CREATED_ASC: "created_asc",
};

export const SORT_OPTION_LABELS = {
  [SORT_OPTIONS.DUE_DATE_DESC]: "Due Date (Newest)",
  [SORT_OPTIONS.DUE_DATE_ASC]: "Due Date (Oldest)",
  [SORT_OPTIONS.AMOUNT_DESC]: "Amount (High to Low)",
  [SORT_OPTIONS.AMOUNT_ASC]: "Amount (Low to High)",
  [SORT_OPTIONS.CREATED_DESC]: "Created (Newest)",
  [SORT_OPTIONS.CREATED_ASC]: "Created (Oldest)",
};

// ========================================
// FILTER OPTIONS
// ========================================

export const FILTER_OPTIONS = {
  ALL: "all",
  UPCOMING: "upcoming",
  DUE_SOON: "due_soon",
  OVERDUE: "overdue",
  PAID: "paid",
  UNPAID: "unpaid",
  PARTIAL: "partial",
};

export const FILTER_OPTION_LABELS = {
  [FILTER_OPTIONS.ALL]: "All Cycles",
  [FILTER_OPTIONS.UPCOMING]: "Upcoming",
  [FILTER_OPTIONS.DUE_SOON]: "Due Soon",
  [FILTER_OPTIONS.OVERDUE]: "Overdue",
  [FILTER_OPTIONS.PAID]: "Paid",
  [FILTER_OPTIONS.UNPAID]: "Unpaid",
  [FILTER_OPTIONS.PARTIAL]: "Partial",
};

// ========================================
// ICON MAPPINGS
// ========================================

export const STATUS_ICONS = {
  // Payment status icons
  [PAYMENT_STATUSES.CONFIRMED]: "CheckCircle",
  [PAYMENT_STATUSES.REJECTED]: "XCircle",
  [PAYMENT_STATUSES.PENDING]: "Clock",
  [PAYMENT_STATUSES.PAID]: "CheckCircle",
  [PAYMENT_STATUSES.UNPAID]: "AlertCircle",
  [PAYMENT_STATUSES.PARTIAL]: "Clock",

  // General status icons
  SUCCESS: "CheckCircle",
  ERROR: "XCircle",
  WARNING: "AlertTriangle",
  INFO: "Info",
  LOADING: "Clock",
};

export const STATUS_COLORS = {
  SUCCESS: "text-green-600",
  ERROR: "text-red-600",
  WARNING: "text-yellow-600",
  INFO: "text-blue-600",
  MUTED: "text-gray-600",
};

// ========================================
// VALIDATION CONSTANTS
// ========================================

export const VALIDATION_LIMITS = {
  MIN_AMOUNT: 0.01,
  MAX_AMOUNT: 999999.99,
  MIN_MEMBERS: 1,
  MAX_MEMBERS: 100,
  MIN_PROJECT_NAME_LENGTH: 1,
  MAX_PROJECT_NAME_LENGTH: 255,
  MAX_DESCRIPTION_LENGTH: 1000,
  MAX_PAYMENT_INSTRUCTIONS_LENGTH: 2000,
};

// ========================================
// API ENDPOINTS
// ========================================

export const API_ENDPOINTS = {
  BILLING_CYCLES: "/projects/:projectId/billing_cycles",
  GENERATE_UPCOMING: "/projects/:projectId/billing_cycles/generate_upcoming",
  PAYMENTS: "/projects/:projectId/payments",
  PROJECTS: "/projects",
  INVITATIONS: "/projects/:projectId/invitations",
};

// Helper function to replace URL parameters
export function buildApiUrl(endpoint, params = {}) {
  let url = endpoint;
  Object.keys(params).forEach(key => {
    url = url.replace(`:${key}`, params[key]);
  });
  return url;
} 