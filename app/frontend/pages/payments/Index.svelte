<script>
  import { router } from "@inertiajs/svelte";

  export let payments;

  let filterStatus = "all";
  let searchTerm = "";

  $: filteredPayments = payments.filter((payment) => {
    const matchesStatus =
      filterStatus === "all" || payment.status === filterStatus;
    const matchesSearch =
      searchTerm === "" ||
      payment.project?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      payment.transaction_id?.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesStatus && matchesSearch;
  });

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
      month: "short",
      day: "numeric",
    });
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

  function viewPayment(paymentId) {
    router.visit(`/payments/${paymentId}`);
  }

  function getStatusCounts() {
    return {
      all: payments.length,
      pending: payments.filter((p) => p.status === "pending").length,
      confirmed: payments.filter((p) => p.status === "confirmed").length,
      rejected: payments.filter((p) => p.status === "rejected").length,
    };
  }

  $: statusCounts = getStatusCounts();
</script>

<div class="payments-container">
  <div class="header">
    <h1>My Payments</h1>
    <p class="subtitle">View and manage all your payment submissions</p>
  </div>

  <div class="controls">
    <div class="search-section">
      <div class="search-input">
        <input
          type="text"
          placeholder="Search by project or transaction ID..."
          bind:value={searchTerm}
        />
        <div class="search-icon">🔍</div>
      </div>
    </div>

    <div class="filter-section">
      <div class="filter-tabs">
        <button
          class="filter-tab {filterStatus === 'all' ? 'active' : ''}"
          on:click={() => (filterStatus = "all")}
        >
          All ({statusCounts.all})
        </button>
        <button
          class="filter-tab {filterStatus === 'pending' ? 'active' : ''}"
          on:click={() => (filterStatus = "pending")}
        >
          ⏳ Pending ({statusCounts.pending})
        </button>
        <button
          class="filter-tab {filterStatus === 'confirmed' ? 'active' : ''}"
          on:click={() => (filterStatus = "confirmed")}
        >
          ✅ Confirmed ({statusCounts.confirmed})
        </button>
        <button
          class="filter-tab {filterStatus === 'rejected' ? 'active' : ''}"
          on:click={() => (filterStatus = "rejected")}
        >
          ❌ Rejected ({statusCounts.rejected})
        </button>
      </div>
    </div>
  </div>

  {#if filteredPayments.length === 0}
    <div class="empty-state">
      {#if payments.length === 0}
        <div class="empty-icon">💳</div>
        <h2>No payments yet</h2>
        <p>You haven't submitted any payment evidence yet.</p>
        <button
          class="btn btn-primary"
          on:click={() => router.visit("/projects")}
        >
          View Projects
        </button>
      {:else}
        <div class="empty-icon">🔍</div>
        <h2>No payments found</h2>
        <p>No payments match your current filters.</p>
        <button
          class="btn btn-secondary"
          on:click={() => {
            filterStatus = "all";
            searchTerm = "";
          }}
        >
          Clear Filters
        </button>
      {/if}
    </div>
  {:else}
    <div class="payments-grid">
      {#each filteredPayments as payment}
        <div
          class="payment-card"
          on:click={() => viewPayment(payment.id)}
          on:keydown={(e) =>
            (e.key === "Enter" || e.key === " ") && viewPayment(payment.id)}
          role="button"
          tabindex="0"
        >
          <div class="card-header">
            <div class="project-info">
              <h3 class="project-name">
                {payment.billing_cycle?.project?.name || "Unknown Project"}
              </h3>
              <p class="cycle-name">
                Due: {payment.billing_cycle?.due_date
                  ? new Date(
                      payment.billing_cycle.due_date,
                    ).toLocaleDateString()
                  : "Unknown Date"}
              </p>
            </div>
            <div
              class="status-badge"
              style="background-color: {getStatusColor(
                payment.status,
              )}20; color: {getStatusColor(payment.status)};"
            >
              <span class="status-icon">{getStatusIcon(payment.status)}</span>
              <span class="status-text">{payment.status}</span>
            </div>
          </div>

          <div class="card-content">
            <div class="payment-details">
              <div class="detail-item">
                <span class="detail-label">Amount:</span>
                <span class="amount">{formatCurrency(payment.amount)}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">Submitted:</span>
                <span>{formatDate(payment.created_at)}</span>
              </div>
              {#if payment.confirmation_date}
                <div class="detail-item">
                  <span class="detail-label">Confirmed:</span>
                  <span>{formatDate(payment.confirmation_date)}</span>
                </div>
              {/if}
            </div>

            <div class="evidence-info">
              {#if payment.has_evidence}
                <div class="evidence-indicator">
                  <span class="evidence-icon">📎</span>
                  <span>File attached</span>
                </div>
              {/if}
              {#if payment.transaction_id}
                <div class="transaction-indicator">
                  <span class="transaction-icon">🔢</span>
                  <span>Transaction ID: {payment.transaction_id}</span>
                </div>
              {/if}
              {#if !payment.has_evidence && !payment.transaction_id}
                <div class="no-evidence-indicator">
                  <span class="no-evidence-icon">⚠️</span>
                  <span>No evidence provided</span>
                </div>
              {/if}
            </div>
          </div>

          <div class="card-footer">
            <span class="view-link">View Details →</span>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .payments-container {
    max-width: 1200px;
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

  .controls {
    margin-bottom: 2rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .search-section {
    display: flex;
    justify-content: center;
  }

  .search-input {
    position: relative;
    max-width: 400px;
    width: 100%;
  }

  .search-input input {
    width: 100%;
    padding: 0.75rem 1rem 0.75rem 2.5rem;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    font-size: 1rem;
    transition: border-color 0.2s ease;
  }

  .search-input input:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }

  .search-icon {
    position: absolute;
    left: 0.75rem;
    top: 50%;
    transform: translateY(-50%);
    color: #6b7280;
  }

  .filter-section {
    display: flex;
    justify-content: center;
  }

  .filter-tabs {
    display: flex;
    background: #f3f4f6;
    border-radius: 8px;
    padding: 0.25rem;
    gap: 0.25rem;
  }

  .filter-tab {
    padding: 0.5rem 1rem;
    border: none;
    background: transparent;
    border-radius: 6px;
    font-size: 0.875rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
    color: #6b7280;
  }

  .filter-tab:hover {
    background: #e5e7eb;
    color: #374151;
  }

  .filter-tab.active {
    background: white;
    color: #374151;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  }

  .empty-state {
    text-align: center;
    padding: 4rem 2rem;
    background: #f9fafb;
    border-radius: 8px;
    border: 1px solid #e5e7eb;
  }

  .empty-icon {
    font-size: 3rem;
    margin-bottom: 1rem;
  }

  .empty-state h2 {
    margin: 0 0 0.5rem 0;
    color: #374151;
    font-size: 1.5rem;
    font-weight: 600;
  }

  .empty-state p {
    margin: 0 0 1.5rem 0;
    color: #6b7280;
    font-size: 1rem;
  }

  .payments-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 1.5rem;
  }

  .payment-card {
    background: white;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .payment-card:hover {
    border-color: #3b82f6;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    transform: translateY(-1px);
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 1rem;
  }

  .project-info {
    flex: 1;
  }

  .project-name {
    margin: 0 0 0.25rem 0;
    color: #1f2937;
    font-size: 1.125rem;
    font-weight: 600;
    line-height: 1.3;
  }

  .cycle-name {
    margin: 0;
    color: #6b7280;
    font-size: 0.875rem;
  }

  .status-badge {
    padding: 0.375rem 0.75rem;
    border-radius: 16px;
    font-weight: 600;
    font-size: 0.75rem;
    display: flex;
    align-items: center;
    gap: 0.375rem;
    white-space: nowrap;
  }

  .status-icon {
    font-size: 0.875rem;
  }

  .card-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .payment-details {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 0.75rem;
  }

  .detail-item {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }

  .detail-label {
    font-weight: 500;
    color: #6b7280;
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .detail-item span {
    color: #374151;
    font-weight: 500;
    font-size: 0.875rem;
  }

  .amount {
    color: #059669 !important;
    font-weight: 600 !important;
    font-size: 1rem !important;
  }

  .evidence-info {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .evidence-indicator,
  .transaction-indicator,
  .no-evidence-indicator {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
  }

  .evidence-indicator {
    color: #059669;
  }

  .transaction-indicator {
    color: #3b82f6;
  }

  .no-evidence-indicator {
    color: #d97706;
  }

  .evidence-icon,
  .transaction-icon,
  .no-evidence-icon {
    font-size: 1rem;
  }

  .card-footer {
    display: flex;
    justify-content: flex-end;
    padding-top: 0.5rem;
    border-top: 1px solid #f3f4f6;
  }

  .view-link {
    color: #3b82f6;
    font-size: 0.875rem;
    font-weight: 500;
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

  @media (max-width: 768px) {
    .payments-container {
      padding: 1rem;
    }

    .payments-grid {
      grid-template-columns: 1fr;
    }

    .filter-tabs {
      flex-wrap: wrap;
      justify-content: center;
    }

    .filter-tab {
      font-size: 0.75rem;
      padding: 0.375rem 0.75rem;
    }

    .card-header {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.75rem;
    }

    .payment-details {
      grid-template-columns: 1fr;
    }
  }
</style>
