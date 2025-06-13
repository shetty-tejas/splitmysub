<script>
  import { router } from "@inertiajs/svelte";

  export let payment;
  export let billing_cycle;
  export let project;
  export let errors = [];

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    if (!dateString) return "Not set";
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function formatDateTime(dateString) {
    if (!dateString) return "Not set";
    return new Date(dateString).toLocaleString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function formatFileSize(bytes) {
    if (!bytes) return "";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }

  function getStatusColor(status) {
    switch (status) {
      case "confirmed":
        return "#059669";
      case "rejected":
        return "#dc2626";
      case "pending":
      default:
        return "#d97706";
    }
  }

  function getStatusIcon(status) {
    switch (status) {
      case "confirmed":
        return "✅";
      case "rejected":
        return "❌";
      case "pending":
      default:
        return "⏳";
    }
  }

  function downloadEvidence() {
    window.open(`/payments/${payment.id}/download_evidence`, "_blank");
  }

  function deletePayment() {
    if (
      confirm(
        "Are you sure you want to delete this payment evidence? This action cannot be undone.",
      )
    ) {
      router.delete(`/payments/${payment.id}`, {
        onSuccess: () => {
          router.visit("/payments");
        },
      });
    }
  }
</script>

<div class="payment-detail-container">
  <div class="header">
    <div class="header-content">
      <h1>Payment Details</h1>
      <div
        class="status-badge"
        style="background-color: {getStatusColor(
          payment.status,
        )}20; color: {getStatusColor(payment.status)};"
      >
        <span class="status-icon">{getStatusIcon(payment.status)}</span>
        <span class="status-text"
          >{payment.status.charAt(0).toUpperCase() +
            payment.status.slice(1)}</span
        >
      </div>
    </div>
    <p class="subtitle">
      Payment for <strong>{project.name}</strong> - Due {new Date(
        billing_cycle.due_date,
      ).toLocaleDateString()}
    </p>
  </div>

  {#if errors.length > 0}
    <div class="error-banner">
      <h3>Errors:</h3>
      <ul>
        {#each errors as error}
          <li>{error}</li>
        {/each}
      </ul>
    </div>
  {/if}

  <div class="content-grid">
    <div class="main-content">
      <div class="info-section">
        <h2>Payment Information</h2>
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">Amount Paid:</span>
            <span class="amount">{formatCurrency(payment.amount)}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Expected Amount:</span>
            <span
              >{formatCurrency(billing_cycle.expected_payment_per_member)}</span
            >
          </div>
          <div class="info-item">
            <span class="info-label">Status:</span>
            <span
              style="color: {getStatusColor(payment.status)}; font-weight: 600;"
            >
              {getStatusIcon(payment.status)}
              {payment.status.charAt(0).toUpperCase() + payment.status.slice(1)}
            </span>
          </div>
          <div class="info-item">
            <span class="info-label">Submitted:</span>
            <span>{formatDateTime(payment.created_at)}</span>
          </div>
          {#if payment.confirmation_date}
            <div class="info-item">
              <span class="info-label">Confirmed:</span>
              <span>{formatDate(payment.confirmation_date)}</span>
            </div>
          {/if}
          {#if payment.transaction_id}
            <div class="info-item">
              <span class="info-label">Transaction ID:</span>
              <span class="transaction-id">{payment.transaction_id}</span>
            </div>
          {/if}
        </div>

        {#if payment.notes}
          <div class="notes-section">
            <h3>Notes</h3>
            <p class="notes-text">{payment.notes}</p>
          </div>
        {/if}
      </div>

      <div class="billing-cycle-section">
        <h2>Billing Cycle Details</h2>
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">Due Date:</span>
            <span>{formatDate(billing_cycle.due_date)}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Total Amount:</span>
            <span>{formatCurrency(billing_cycle.total_amount)}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Expected Per Member:</span>
            <span
              >{formatCurrency(billing_cycle.expected_payment_per_member)}</span
            >
          </div>
        </div>
      </div>
    </div>

    <div class="sidebar">
      {#if payment.has_evidence}
        <div class="evidence-section">
          <h2>Payment Evidence</h2>
          <div class="evidence-card">
            <div class="evidence-info">
              <div class="file-icon">
                {#if payment.evidence_content_type?.startsWith("image/")}
                  🖼️
                {:else if payment.evidence_content_type === "application/pdf"}
                  📄
                {:else}
                  📎
                {/if}
              </div>
              <div class="file-details">
                <p class="file-name">{payment.evidence_filename}</p>
                <p class="file-size">
                  {formatFileSize(payment.evidence_byte_size)}
                </p>
                <p class="file-type">{payment.evidence_content_type}</p>
              </div>
            </div>

            {#if payment.evidence_content_type?.startsWith("image/")}
              <div class="image-preview">
                <img src={payment.evidence_url} alt="Payment evidence" />
              </div>
            {/if}

            <button
              type="button"
              class="btn btn-primary"
              on:click={downloadEvidence}
            >
              📥 Download Evidence
            </button>
          </div>
        </div>
      {:else}
        <div class="no-evidence-section">
          <h2>Payment Evidence</h2>
          <div class="no-evidence-card">
            <div class="no-evidence-icon">📎</div>
            <p>No file evidence uploaded</p>
            {#if payment.transaction_id}
              <p class="transaction-note">Transaction ID provided instead</p>
            {/if}
          </div>
        </div>
      {/if}

      <div class="actions-section">
        <h2>Actions</h2>
        <div class="action-buttons">
          <button
            type="button"
            class="btn btn-secondary"
            on:click={() => router.visit("/payments")}
          >
            ← Back to Payments
          </button>

          <button
            type="button"
            class="btn btn-secondary"
            on:click={() => router.visit(`/projects/${project.id}`)}
          >
            View Project
          </button>

          {#if payment.status === "pending"}
            <button
              type="button"
              class="btn btn-danger"
              on:click={deletePayment}
            >
              🗑️ Delete Payment
            </button>
          {/if}
        </div>
      </div>
    </div>
  </div>
</div>

<style>
  .payment-detail-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }

  .header {
    margin-bottom: 2rem;
  }

  .header-content {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 0.5rem;
  }

  .header h1 {
    margin: 0;
    color: #1f2937;
    font-size: 2rem;
    font-weight: 700;
  }

  .status-badge {
    padding: 0.5rem 1rem;
    border-radius: 20px;
    font-weight: 600;
    font-size: 0.875rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .status-icon {
    font-size: 1rem;
  }

  .subtitle {
    margin: 0;
    color: #6b7280;
    font-size: 1.125rem;
  }

  .error-banner {
    background: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 2rem;
  }

  .error-banner h3 {
    margin: 0 0 0.5rem 0;
    color: #dc2626;
    font-size: 1rem;
    font-weight: 600;
  }

  .error-banner ul {
    margin: 0;
    padding-left: 1.5rem;
    color: #dc2626;
  }

  .content-grid {
    display: grid;
    grid-template-columns: 1fr 350px;
    gap: 2rem;
  }

  .main-content {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .info-section,
  .billing-cycle-section,
  .evidence-section,
  .no-evidence-section,
  .actions-section {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1.5rem;
  }

  .info-section h2,
  .billing-cycle-section h2,
  .evidence-section h2,
  .no-evidence-section h2,
  .actions-section h2 {
    margin: 0 0 1.5rem 0;
    color: #374151;
    font-size: 1.25rem;
    font-weight: 600;
  }

  .info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
  }

  .info-item {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .info-label {
    font-weight: 500;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .info-item span {
    color: #374151;
    font-weight: 500;
  }

  .amount {
    color: #059669 !important;
    font-weight: 600 !important;
    font-size: 1.25rem !important;
  }

  .transaction-id {
    font-family: monospace;
    background: #f3f4f6;
    padding: 0.25rem 0.5rem;
    border-radius: 4px;
    font-size: 0.875rem !important;
  }

  .notes-section {
    margin-top: 1.5rem;
    padding-top: 1.5rem;
    border-top: 1px solid #e5e7eb;
  }

  .notes-section h3 {
    margin: 0 0 0.75rem 0;
    color: #374151;
    font-size: 1rem;
    font-weight: 600;
  }

  .notes-text {
    margin: 0;
    color: #6b7280;
    line-height: 1.6;
    white-space: pre-wrap;
  }

  .sidebar {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .evidence-card,
  .no-evidence-card {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .evidence-info {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .file-icon {
    font-size: 1.5rem;
  }

  .file-details {
    flex: 1;
  }

  .file-name {
    margin: 0;
    font-weight: 500;
    color: #374151;
    word-break: break-all;
    font-size: 0.875rem;
  }

  .file-size,
  .file-type {
    margin: 0;
    font-size: 0.75rem;
    color: #6b7280;
  }

  .image-preview {
    border: 1px solid #e5e7eb;
    border-radius: 6px;
    overflow: hidden;
  }

  .image-preview img {
    width: 100%;
    height: auto;
    max-height: 200px;
    object-fit: contain;
  }

  .no-evidence-card {
    text-align: center;
    padding: 2rem 1rem;
    background: #f9fafb;
    border-radius: 6px;
  }

  .no-evidence-icon {
    font-size: 2rem;
    margin-bottom: 0.5rem;
  }

  .no-evidence-card p {
    margin: 0;
    color: #6b7280;
  }

  .transaction-note {
    font-size: 0.875rem !important;
    font-style: italic;
  }

  .action-buttons {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .btn {
    padding: 0.75rem 1rem;
    border-radius: 6px;
    font-weight: 500;
    font-size: 0.875rem;
    cursor: pointer;
    transition: all 0.2s ease;
    border: none;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
  }

  .btn-primary {
    background: #3b82f6;
    color: white;
  }

  .btn-primary:hover {
    background: #2563eb;
  }

  .btn-secondary {
    background: #f3f4f6;
    color: #374151;
    border: 1px solid #d1d5db;
  }

  .btn-secondary:hover {
    background: #e5e7eb;
  }

  .btn-danger {
    background: #ef4444;
    color: white;
  }

  .btn-danger:hover {
    background: #dc2626;
  }

  @media (max-width: 768px) {
    .payment-detail-container {
      padding: 1rem;
    }

    .content-grid {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }

    .header-content {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }

    .info-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
