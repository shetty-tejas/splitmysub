<script>
  import Layout from "../../layouts/layout.svelte";
  import * as Card from "$lib/components/ui/card/index.js";
  import { Button } from "$lib/components/ui/button/index.js";
  import { Badge } from "$lib/components/ui/badge/index.js";
  import { Input } from "$lib/components/ui/input/index.js";
  import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
  } from "$lib/components/ui/select/index.js";
  import { Link, router } from "@inertiajs/svelte";
  import {
    ArrowLeft,
    CreditCard,
    Search,
    Filter,
    Download,
    Calendar,
    CheckCircle,
    Clock,
    AlertTriangle,
    Eye,
    ChevronLeft,
    ChevronRight,
  } from "lucide-svelte";
  import { formatCurrency, formatDate } from "$lib/billing-utils";

  export let payments = [];
  export let pagination = {};
  export let filters = {};

  let searchTerm = filters.search || "";
  let statusFilter = filters.status || "";
  let dateFrom = filters.date_from || "";
  let dateTo = filters.date_to || "";

  function getStatusColor(status) {
    switch (status) {
      case "confirmed":
        return "bg-green-100 text-green-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  }

  function getStatusIcon(status) {
    switch (status) {
      case "confirmed":
        return CheckCircle;
      case "pending":
        return Clock;
      case "rejected":
        return AlertTriangle;
      default:
        return Clock;
    }
  }

  function applyFilters() {
    const params = new URLSearchParams();
    if (searchTerm) params.set("search", searchTerm);
    if (statusFilter) params.set("status", statusFilter);
    if (dateFrom) params.set("date_from", dateFrom);
    if (dateTo) params.set("date_to", dateTo);

    router.get("/dashboard/payment_history", Object.fromEntries(params));
  }

  function clearFilters() {
    searchTerm = "";
    statusFilter = "";
    dateFrom = "";
    dateTo = "";
    router.get("/dashboard/payment_history");
  }

  function goToPage(page) {
    const params = new URLSearchParams();
    if (searchTerm) params.set("search", searchTerm);
    if (statusFilter) params.set("status", statusFilter);
    if (dateFrom) params.set("date_from", dateFrom);
    if (dateTo) params.set("date_to", dateTo);
    params.set("page", page);

    router.get("/dashboard/payment_history", Object.fromEntries(params));
  }

  function exportPayments() {
    const params = new URLSearchParams();
    if (searchTerm) params.set("search", searchTerm);
    if (statusFilter) params.set("status", statusFilter);
    if (dateFrom) params.set("date_from", dateFrom);
    if (dateTo) params.set("date_to", dateTo);

    window.location.href = `/dashboard/export_payments?${params.toString()}`;
  }
</script>

<svelte:head>
  <title>Payment History - SplitSub</title>
</svelte:head>

<Layout>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center gap-4 mb-4">
        <Link href="/dashboard">
          <Button variant="outline" size="sm">
            <ArrowLeft class="h-4 w-4 mr-2" />
            Back to Dashboard
          </Button>
        </Link>
      </div>
      <h1 class="text-3xl font-bold text-gray-900">Payment History</h1>
      <p class="mt-2 text-gray-600">View and manage all your payment records</p>
    </div>

    <!-- Filters -->
    <Card.Root class="mb-8">
      <Card.Header>
        <Card.Title class="flex items-center gap-2">
          <Filter class="h-5 w-5" />
          Filters
        </Card.Title>
      </Card.Header>
      <Card.Content>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div>
            <label
              for="search-input"
              class="block text-sm font-medium text-gray-700 mb-2">Search</label
            >
            <div class="relative">
              <Search
                class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400"
              />
              <Input
                id="search-input"
                bind:value={searchTerm}
                placeholder="Search projects..."
                class="pl-10"
                onkeydown={(e) => e.key === "Enter" && applyFilters()}
              />
            </div>
          </div>

          <div>
            <label
              for="status-select"
              class="block text-sm font-medium text-gray-700 mb-2">Status</label
            >
            <Select bind:value={statusFilter}>
              <SelectTrigger id="status-select">
                <SelectValue placeholder="All statuses" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">All statuses</SelectItem>
                <SelectItem value="confirmed">Confirmed</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div>
            <label
              for="date-from"
              class="block text-sm font-medium text-gray-700 mb-2"
              >From Date</label
            >
            <Input id="date-from" type="date" bind:value={dateFrom} />
          </div>

          <div>
            <label
              for="date-to"
              class="block text-sm font-medium text-gray-700 mb-2"
              >To Date</label
            >
            <Input id="date-to" type="date" bind:value={dateTo} />
          </div>

          <div class="flex items-end gap-2">
            <Button onclick={applyFilters} class="flex-1">
              Apply Filters
            </Button>
            <Button variant="outline" onclick={clearFilters}>Clear</Button>
          </div>
        </div>
      </Card.Content>
    </Card.Root>

    <!-- Export Button -->
    <div class="flex justify-end mb-6">
      <Button variant="outline" onclick={exportPayments}>
        <Download class="h-4 w-4 mr-2" />
        Export CSV
      </Button>
    </div>

    <!-- Payments List -->
    <Card.Root>
      <Card.Header>
        <div class="flex items-center justify-between">
          <Card.Title class="flex items-center gap-2">
            <CreditCard class="h-5 w-5" />
            Payment Records
          </Card.Title>
          <div class="text-sm text-gray-500">
            {pagination.total_count || 0} total payments
          </div>
        </div>
      </Card.Header>
      <Card.Content>
        {#if payments.length > 0}
          <div class="space-y-4">
            {#each payments as payment}
              <div
                class="border rounded-lg p-4 hover:shadow-md transition-shadow"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-4">
                    <div class="flex-shrink-0">
                      {#if payment.status === "confirmed"}
                        <CheckCircle class="h-6 w-6 text-green-600" />
                      {:else if payment.status === "pending"}
                        <Clock class="h-6 w-6 text-yellow-600" />
                      {:else}
                        <AlertTriangle class="h-6 w-6 text-red-600" />
                      {/if}
                    </div>
                    <div>
                      <h3 class="text-lg font-medium text-gray-900">
                        {payment.project.name}
                      </h3>
                      <div
                        class="flex items-center gap-4 text-sm text-gray-500"
                      >
                        <span
                          >Payment Date: {formatDate(payment.created_at)}</span
                        >
                        <span
                          >Due Date: {formatDate(
                            payment.billing_cycle.due_date,
                          )}</span
                        >
                        {#if payment.transaction_id}
                          <span>Transaction: {payment.transaction_id}</span>
                        {/if}
                      </div>
                      {#if payment.confirmation_notes}
                        <p class="text-sm text-gray-600 mt-1">
                          {payment.confirmation_notes}
                        </p>
                      {/if}
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-xl font-bold text-gray-900">
                      {formatCurrency(payment.amount)}
                    </p>
                    <Badge class={getStatusColor(payment.status)}>
                      {payment.status}
                    </Badge>
                    {#if payment.confirmation_date}
                      <p class="text-xs text-gray-500 mt-1">
                        Confirmed: {formatDate(payment.confirmation_date)}
                      </p>
                    {/if}
                  </div>
                </div>

                <div class="mt-4 flex items-center justify-between">
                  <div class="flex items-center gap-2 text-sm text-gray-500">
                    <Calendar class="h-4 w-4" />
                    <span
                      >Billing Cycle: {formatCurrency(
                        payment.billing_cycle.total_amount,
                      )} total</span
                    >
                    <span>•</span>
                    <span>{payment.project.billing_cycle} subscription</span>
                  </div>
                  <div class="flex gap-2">
                    <Link href="/projects/{payment.project.slug}">
                      <Button variant="outline" size="sm">
                        <Eye class="h-3 w-3 mr-1" />
                        View Project
                      </Button>
                    </Link>
                    {#if payment.evidence_file_name}
                      <Link href="/payments/{payment.id}/download_evidence">
                        <Button variant="outline" size="sm">
                          <Download class="h-3 w-3 mr-1" />
                          Evidence
                        </Button>
                      </Link>
                    {/if}
                  </div>
                </div>
              </div>
            {/each}
          </div>

          <!-- Pagination -->
          {#if pagination.total_pages > 1}
            <div class="flex items-center justify-between mt-8">
              <div class="text-sm text-gray-500">
                Page {pagination.current_page} of {pagination.total_pages}
                ({pagination.total_count} total payments)
              </div>
              <div class="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={pagination.current_page <= 1}
                  onclick={() => goToPage(pagination.current_page - 1)}
                >
                  <ChevronLeft class="h-4 w-4" />
                  Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={pagination.current_page >= pagination.total_pages}
                  onclick={() => goToPage(pagination.current_page + 1)}
                >
                  Next
                  <ChevronRight class="h-4 w-4" />
                </Button>
              </div>
            </div>
          {/if}
        {:else}
          <div class="text-center py-12">
            <CreditCard class="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              No payments found
            </h3>
            <p class="text-gray-500 mb-6">
              {#if searchTerm || statusFilter || dateFrom || dateTo}
                Try adjusting your filters to see more results.
              {:else}
                You haven't made any payments yet.
              {/if}
            </p>
            {#if searchTerm || statusFilter || dateFrom || dateTo}
              <Button variant="outline" onclick={clearFilters}>
                Clear Filters
              </Button>
            {:else}
              <Link href="/dashboard">
                <Button>Browse Projects</Button>
              </Link>
            {/if}
          </div>
        {/if}
      </Card.Content>
    </Card.Root>
  </div>
</Layout>
