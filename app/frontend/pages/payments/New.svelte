<script>
  import { router } from "@inertiajs/svelte";
  import FileUpload from "../../components/payments/FileUpload.svelte";

  export let payment;
  export let billing_cycle;
  export let project;
  export let errors = [];

  let form = {
    amount: payment.amount || billing_cycle.expected_payment_per_member || "",
    transaction_id: payment.transaction_id || "",
    notes: payment.notes || "",
    evidence: null,
  };

  let submitting = false;
  let fileUploadError = "";

  function handleFileSelected(event) {
    form.evidence = event.detail.file;
    fileUploadError = "";
  }

  function handleFileRemoved() {
    form.evidence = null;
  }

  function handleSubmit() {
    if (submitting) return;

    // Validate that either file or transaction ID is provided
    if (!form.evidence && !form.transaction_id.trim()) {
      fileUploadError =
        "Please either upload payment evidence or provide a transaction ID.";
      return;
    }

    submitting = true;

    const formData = new FormData();
    formData.append("payment[amount]", form.amount);
    formData.append("payment[transaction_id]", form.transaction_id);
    formData.append("payment[notes]", form.notes);

    if (form.evidence) {
      formData.append("payment[evidence]", form.evidence);
    }

    router.post(`/billing_cycles/${billing_cycle.id}/payments`, formData, {
      onFinish: () => {
        submitting = false;
      },
      onError: (errors) => {
        console.error("Payment submission failed:", errors);
      },
    });
  }

  import { formatCurrency } from "$lib/billing-utils";
</script>

<div class="payment-form-container">
  <div class="header">
    <h1>Submit Payment Evidence</h1>
    <p class="subtitle">
      Submit evidence for your payment to <strong>{project.name}</strong>
    </p>
  </div>

  <div class="billing-cycle-info">
    <h2>Billing Cycle Details</h2>
    <div class="info-grid">
      <div class="info-item">
        <span class="info-label">Due Date:</span>
        <span>{new Date(billing_cycle.due_date).toLocaleDateString()}</span>
      </div>
      <div class="info-item">
        <span class="info-label">Total Amount:</span>
        <span
          >{formatCurrency(
            billing_cycle.total_amount,
            billing_cycle.currency,
          )}</span
        >
      </div>
      <div class="info-item">
        <span class="info-label">Expected Amount:</span>
        <span class="amount"
          >{formatCurrency(
            billing_cycle.expected_payment_per_member,
            billing_cycle.currency,
          )}</span
        >
      </div>
    </div>
  </div>

  {#if errors.length > 0}
    <div class="error-banner">
      <h3>Please fix the following errors:</h3>
      <ul>
        {#each errors as error}
          <li>{error}</li>
        {/each}
      </ul>
    </div>
  {/if}

  <form
    onsubmit={(e) => {
      e.preventDefault();
      handleSubmit(e);
    }}
    class="payment-form"
  >
    <div class="form-section">
      <h3>Payment Details</h3>

      <div class="form-group">
        <label for="amount">Payment Amount *</label>
        <div class="input-wrapper">
          <span class="currency-symbol">$</span>
          <input
            id="amount"
            type="number"
            step="0.01"
            min="0"
            bind:value={form.amount}
            required
            disabled={submitting}
            placeholder="0.00"
          />
        </div>
        <p class="help-text">
          Expected amount: {formatCurrency(
            billing_cycle.expected_payment_per_member,
            billing_cycle.currency,
          )}
        </p>
      </div>

      <div class="form-group">
        <label for="transaction_id">Transaction ID</label>
        <input
          id="transaction_id"
          type="text"
          bind:value={form.transaction_id}
          disabled={submitting}
          placeholder="e.g., Venmo transaction ID, bank reference number"
        />
        <p class="help-text">
          Optional: Provide a transaction ID if you have one (alternative to
          file upload)
        </p>
      </div>

      <div class="form-group">
        <label for="notes">Notes</label>
        <textarea
          id="notes"
          bind:value={form.notes}
          disabled={submitting}
          placeholder="Any additional notes about this payment..."
          rows="3"
        ></textarea>
      </div>
    </div>

    <div class="form-section">
      <h3>Payment Evidence</h3>
      <p class="section-description">
        Upload a screenshot or photo of your payment confirmation, or provide a
        transaction ID above.
      </p>

      <FileUpload
        bind:file={form.evidence}
        bind:error={fileUploadError}
        disabled={submitting}
        on:fileSelected={handleFileSelected}
        on:fileRemoved={handleFileRemoved}
      />

      {#if fileUploadError}
        <div class="field-error">
          {fileUploadError}
        </div>
      {/if}
    </div>

    <div class="form-actions">
      <button
        type="button"
        class="btn btn-secondary"
        onclick={() => router.visit(`/projects/${project.slug}`)}
        onkeydown={(e) =>
          (e.key === "Enter" || e.key === " ") &&
          router.visit(`/projects/${project.slug}`)}
        disabled={submitting}
      >
        Cancel
      </button>

      <button type="submit" class="btn btn-primary" disabled={submitting}>
        {submitting ? "Submitting..." : "Submit Payment Evidence"}
      </button>
    </div>
  </form>
</div>

<style>
  .payment-form-container {
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem;
  }

  .header {
    margin-bottom: 2rem;
    text-align: center;
  }

  .header h1 {
    margin: 0 0 0.5rem 0;
    color: #1f2937;
    font-size: 2rem;
    font-weight: 700;
  }

  .subtitle {
    margin: 0;
    color: #6b7280;
    font-size: 1.125rem;
  }

  .billing-cycle-info {
    background: #f9fafb;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;
  }

  .billing-cycle-info h2 {
    margin: 0 0 1rem 0;
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
    font-size: 1.125rem !important;
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

  .payment-form {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .form-section {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1.5rem;
  }

  .form-section h3 {
    margin: 0 0 1rem 0;
    color: #374151;
    font-size: 1.125rem;
    font-weight: 600;
  }

  .section-description {
    margin: 0 0 1.5rem 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .form-group {
    margin-bottom: 1.5rem;
  }

  .form-group:last-child {
    margin-bottom: 0;
  }

  .form-group label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
    color: #374151;
  }

  .input-wrapper {
    position: relative;
    display: flex;
    align-items: center;
  }

  .currency-symbol {
    position: absolute;
    left: 0.75rem;
    color: #6b7280;
    font-weight: 500;
    z-index: 1;
  }

  input,
  textarea {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    font-size: 1rem;
    transition: border-color 0.2s ease;
  }

  input[type="number"] {
    padding-left: 2rem;
  }

  input:focus,
  textarea:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }

  input:disabled,
  textarea:disabled {
    background-color: #f3f4f6;
    color: #6b7280;
    cursor: not-allowed;
  }

  .help-text {
    margin: 0.5rem 0 0 0;
    font-size: 0.875rem;
    color: #6b7280;
  }

  .field-error {
    margin-top: 0.5rem;
    padding: 0.5rem;
    background-color: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 4px;
    color: #dc2626;
    font-size: 0.875rem;
  }

  .form-actions {
    display: flex;
    gap: 1rem;
    justify-content: flex-end;
    padding-top: 1rem;
    border-top: 1px solid #e5e7eb;
  }

  .btn {
    padding: 0.75rem 1.5rem;
    border-radius: 6px;
    font-weight: 500;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.2s ease;
    border: none;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
  }

  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-primary {
    background: #3b82f6;
    color: white;
  }

  .btn-primary:hover:not(:disabled) {
    background: #2563eb;
  }

  .btn-secondary {
    background: #f3f4f6;
    color: #374151;
    border: 1px solid #d1d5db;
  }

  .btn-secondary:hover:not(:disabled) {
    background: #e5e7eb;
  }

  @media (max-width: 640px) {
    .payment-form-container {
      padding: 1rem;
    }

    .info-grid {
      grid-template-columns: 1fr;
    }

    .form-actions {
      flex-direction: column;
    }

    .btn {
      width: 100%;
    }
  }
</style>
