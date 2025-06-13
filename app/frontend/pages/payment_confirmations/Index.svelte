<script>
  import { router } from "@inertiajs/svelte";
  import Layout from "../../layouts/layout.svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Badge } from "$lib/components/ui/badge";
  import { Input } from "$lib/components/ui/input";
  import { Checkbox } from "$lib/components/ui/checkbox";
  import {
    ArrowLeft,
    Search,
    Filter,
    Download,
    Check,
    X,
    AlertTriangle,
    FileText,
    Calendar,
    DollarSign,
    Users,
    Eye,
  } from "lucide-svelte";

  export let project;
  export let payments;
  export let filters;
  export let stats;

  let selectedPayments = [];
  let batchAction = "";
  let batchNotes = "";
  let showBatchModal = false;
  let searchTerm = filters.search || "";
  let statusFilter = filters.status || "";
  let disputedFilter = filters.disputed || "";
  let sortBy = filters.sort || "date_desc";

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

  function formatDateTime(dateString) {
    if (!dateString) return "Not set";
    return new Date(dateString).toLocaleString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function getStatusColor(status) {
    switch (status) {
      case "confirmed":
        return "bg-green-100 text-green-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      case "pending":
      default:
        return "bg-yellow-100 text-yellow-800";
    }
  }

  function getStatusIcon(status) {
    switch (status) {
      case "confirmed":
        return Check;
      case "rejected":
        return X;
      case "pending":
      default:
        return AlertTriangle;
    }
  }

  function applyFilters() {
    const params = new URLSearchParams();
    if (searchTerm) params.set("search", searchTerm);
    if (statusFilter) params.set("status", statusFilter);
    if (disputedFilter) params.set("disputed", disputedFilter);
    if (sortBy) params.set("sort", sortBy);

    router.get(
      `/projects/${project.id}/payment_confirmations?${params.toString()}`,
    );
  }

  function clearFilters() {
    searchTerm = "";
    statusFilter = "";
    disputedFilter = "";
    sortBy = "date_desc";
    router.get(`/projects/${project.id}/payment_confirmations`);
  }

  function viewPayment(paymentId) {
    router.get(`/projects/${project.id}/payment_confirmations/${paymentId}`);
  }

  function downloadEvidence(paymentId) {
    window.open(`/payments/${paymentId}/download_evidence`, "_blank");
  }

  function togglePaymentSelection(paymentId) {
    if (selectedPayments.includes(paymentId)) {
      selectedPayments = selectedPayments.filter((id) => id !== paymentId);
    } else {
      selectedPayments = [...selectedPayments, paymentId];
    }
  }

  function selectAllPayments() {
    if (selectedPayments.length === payments.length) {
      selectedPayments = [];
    } else {
      selectedPayments = payments.map((p) => p.id);
    }
  }

  function openBatchModal() {
    if (selectedPayments.length === 0) {
      alert("Please select at least one payment.");
      return;
    }
    showBatchModal = true;
  }

  function closeBatchModal() {
    showBatchModal = false;
    batchAction = "";
    batchNotes = "";
  }

  function submitBatchAction() {
    if (!batchAction) {
      alert("Please select an action.");
      return;
    }

    const formData = new FormData();
    formData.append("action_type", batchAction);
    formData.append("notes", batchNotes);
    selectedPayments.forEach((id) => {
      formData.append("payment_ids[]", id);
    });

    router.patch(
      `/projects/${project.id}/payment_confirmations/batch_update`,
      formData,
      {
        onSuccess: () => {
          selectedPayments = [];
          closeBatchModal();
        },
      },
    );
  }

  function goBack() {
    router.get(`/projects/${project.id}`);
  }
</script>

<svelte:head>
  <title>Payment Confirmations - {project.name} - SplitSub</title>
</svelte:head>

<Layout>
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <button
          type="button"
          on:click={goBack}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Project
        </button>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">
        Payment Confirmations
      </h1>
      <p class="text-muted-foreground text-lg">
        Review and manage payment evidence for <strong>{project.name}</strong>
      </p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4 mb-8">
      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <FileText class="h-4 w-4 text-muted-foreground" />
            <div>
              <p class="text-2xl font-bold">{stats.total}</p>
              <p class="text-xs text-muted-foreground">Total</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <AlertTriangle class="h-4 w-4 text-yellow-600" />
            <div>
              <p class="text-2xl font-bold">{stats.pending}</p>
              <p class="text-xs text-muted-foreground">Pending</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <Check class="h-4 w-4 text-green-600" />
            <div>
              <p class="text-2xl font-bold">{stats.confirmed}</p>
              <p class="text-xs text-muted-foreground">Confirmed</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <X class="h-4 w-4 text-red-600" />
            <div>
              <p class="text-2xl font-bold">{stats.rejected}</p>
              <p class="text-xs text-muted-foreground">Rejected</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <AlertTriangle class="h-4 w-4 text-orange-600" />
            <div>
              <p class="text-2xl font-bold">{stats.disputed}</p>
              <p class="text-xs text-muted-foreground">Disputed</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <FileText class="h-4 w-4 text-blue-600" />
            <div>
              <p class="text-2xl font-bold">{stats.with_evidence}</p>
              <p class="text-xs text-muted-foreground">With Evidence</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <FileText class="h-4 w-4 text-gray-600" />
            <div>
              <p class="text-2xl font-bold">{stats.without_evidence}</p>
              <p class="text-xs text-muted-foreground">No Evidence</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Filters and Search -->
    <Card class="mb-6">
      <CardContent class="p-6">
        <div class="flex flex-col lg:flex-row gap-4">
          <!-- Search -->
          <div class="flex-1">
            <div class="relative">
              <Search
                class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground"
              />
              <Input
                type="text"
                placeholder="Search by email, transaction ID, or notes..."
                bind:value={searchTerm}
                class="pl-10"
                on:keydown={(e) => e.key === "Enter" && applyFilters()}
              />
            </div>
          </div>

          <!-- Status Filter -->
          <select
            bind:value={statusFilter}
            class="px-3 py-2 border border-input bg-background rounded-md text-sm"
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="confirmed">Confirmed</option>
            <option value="rejected">Rejected</option>
          </select>

          <!-- Disputed Filter -->
          <select
            bind:value={disputedFilter}
            class="px-3 py-2 border border-input bg-background rounded-md text-sm"
          >
            <option value="">All Payments</option>
            <option value="true">Disputed Only</option>
          </select>

          <!-- Sort -->
          <select
            bind:value={sortBy}
            class="px-3 py-2 border border-input bg-background rounded-md text-sm"
          >
            <option value="date_desc">Newest First</option>
            <option value="date_asc">Oldest First</option>
            <option value="amount_desc">Highest Amount</option>
            <option value="amount_asc">Lowest Amount</option>
            <option value="status">By Status</option>
          </select>

          <!-- Filter Buttons -->
          <div class="flex gap-2">
            <Button on:click={applyFilters} size="sm">
              <Filter class="h-4 w-4 mr-2" />
              Apply
            </Button>
            <Button on:click={clearFilters} variant="outline" size="sm">
              Clear
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- Batch Actions -->
    {#if selectedPayments.length > 0}
      <Card class="mb-6 border-blue-200 bg-blue-50">
        <CardContent class="p-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium">
                {selectedPayments.length} payment(s) selected
              </span>
              <Button on:click={openBatchModal} size="sm">Batch Actions</Button>
            </div>
            <Button
              on:click={() => (selectedPayments = [])}
              variant="outline"
              size="sm"
            >
              Clear Selection
            </Button>
          </div>
        </CardContent>
      </Card>
    {/if}

    <!-- Payments Table -->
    <Card>
      <CardHeader>
        <div class="flex items-center justify-between">
          <div>
            <CardTitle>Payment Evidence</CardTitle>
            <CardDescription>
              Review and confirm payment submissions from project members
            </CardDescription>
          </div>
          {#if payments.length > 0}
            <div class="flex items-center gap-2">
              <Checkbox
                checked={selectedPayments.length === payments.length}
                on:change={selectAllPayments}
              />
              <span class="text-sm text-muted-foreground">Select All</span>
            </div>
          {/if}
        </div>
      </CardHeader>
      <CardContent class="p-0">
        {#if payments.length === 0}
          <div class="text-center py-12">
            <FileText class="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
            <h3 class="text-lg font-semibold mb-2">No payments found</h3>
            <p class="text-muted-foreground">
              No payment evidence matches your current filters.
            </p>
          </div>
        {:else}
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead class="border-b">
                <tr class="text-left">
                  <th class="p-4 w-12"></th>
                  <th class="p-4">Member</th>
                  <th class="p-4">Amount</th>
                  <th class="p-4">Status</th>
                  <th class="p-4">Evidence</th>
                  <th class="p-4">Due Date</th>
                  <th class="p-4">Submitted</th>
                  <th class="p-4">Actions</th>
                </tr>
              </thead>
              <tbody>
                {#each payments as payment}
                  <tr class="border-b hover:bg-muted/50">
                    <td class="p-4">
                      <Checkbox
                        checked={selectedPayments.includes(payment.id)}
                        on:change={() => togglePaymentSelection(payment.id)}
                      />
                    </td>
                    <td class="p-4">
                      <div>
                        <p class="font-medium">{payment.user.email_address}</p>
                        {#if payment.transaction_id}
                          <p class="text-sm text-muted-foreground">
                            ID: {payment.transaction_id}
                          </p>
                        {/if}
                      </div>
                    </td>
                    <td class="p-4">
                      <div>
                        <p class="font-medium">
                          {formatCurrency(payment.amount)}
                        </p>
                        <p class="text-sm text-muted-foreground">
                          Expected: {formatCurrency(
                            payment.billing_cycle.total_amount /
                              (project.cost / project.cost_per_member),
                          )}
                        </p>
                      </div>
                    </td>
                    <td class="p-4">
                      <div class="flex flex-col gap-1">
                        <Badge class={getStatusColor(payment.status)}>
                          <svelte:component
                            this={getStatusIcon(payment.status)}
                            class="h-3 w-3 mr-1"
                          />
                          {payment.status}
                        </Badge>
                        {#if payment.disputed}
                          <Badge class="bg-orange-100 text-orange-800">
                            <AlertTriangle class="h-3 w-3 mr-1" />
                            Disputed
                          </Badge>
                        {/if}
                      </div>
                    </td>
                    <td class="p-4">
                      {#if payment.has_evidence}
                        <div class="flex items-center gap-2">
                          <FileText class="h-4 w-4 text-blue-600" />
                          <span class="text-sm">
                            {payment.evidence_filename}
                          </span>
                          <Button
                            on:click={() => downloadEvidence(payment.id)}
                            variant="ghost"
                            size="sm"
                          >
                            <Download class="h-4 w-4" />
                          </Button>
                        </div>
                      {:else}
                        <span class="text-sm text-muted-foreground">
                          No file
                        </span>
                      {/if}
                    </td>
                    <td class="p-4">
                      <span class="text-sm">
                        {formatDate(payment.billing_cycle.due_date)}
                      </span>
                    </td>
                    <td class="p-4">
                      <span class="text-sm">
                        {formatDateTime(payment.created_at)}
                      </span>
                    </td>
                    <td class="p-4">
                      <Button
                        on:click={() => viewPayment(payment.id)}
                        variant="outline"
                        size="sm"
                      >
                        <Eye class="h-4 w-4 mr-2" />
                        Review
                      </Button>
                    </td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        {/if}
      </CardContent>
    </Card>
  </div>

  <!-- Batch Action Modal -->
  {#if showBatchModal}
    <div
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      on:click={closeBatchModal}
      on:keydown={(e) => e.key === "Escape" && closeBatchModal()}
      role="dialog"
      aria-modal="true"
      aria-labelledby="batch-modal-title"
      tabindex="-1"
    >
      <div
        class="bg-white rounded-lg p-6 w-full max-w-md mx-4"
        on:click|stopPropagation
        on:keydown={() => {}}
        role="document"
      >
        <h3 id="batch-modal-title" class="text-lg font-semibold mb-4">
          Batch Action ({selectedPayments.length} payments)
        </h3>

        <div class="space-y-4">
          <div>
            <label
              for="batch-action-select"
              class="block text-sm font-medium mb-2">Action</label
            >
            <select
              id="batch-action-select"
              bind:value={batchAction}
              class="w-full px-3 py-2 border border-input bg-background rounded-md text-sm"
            >
              <option value="">Select action...</option>
              <option value="confirm">Confirm Payments</option>
              <option value="reject">Reject Payments</option>
            </select>
          </div>

          <div>
            <label
              for="batch-notes-textarea"
              class="block text-sm font-medium mb-2">Notes (Optional)</label
            >
            <textarea
              id="batch-notes-textarea"
              bind:value={batchNotes}
              placeholder="Add notes for this batch action..."
              class="w-full px-3 py-2 border border-input bg-background rounded-md text-sm"
              rows="3"
            ></textarea>
          </div>
        </div>

        <div class="flex justify-end gap-2 mt-6">
          <Button on:click={closeBatchModal} variant="outline">Cancel</Button>
          <Button on:click={submitBatchAction}>Apply Action</Button>
        </div>
      </div>
    </div>
  {/if}
</Layout>
