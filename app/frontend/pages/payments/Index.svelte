<script>
  import { router } from "@inertiajs/svelte";
  import Layout from "../../layouts/layout.svelte";
  import Button from "$lib/components/ui/button/button.svelte";
  import Input from "$lib/components/ui/input/input.svelte";
  import Card from "$lib/components/ui/card/card.svelte";
  import CardContent from "$lib/components/ui/card/card-content.svelte";
  import CardHeader from "$lib/components/ui/card/card-header.svelte";
  import CardTitle from "$lib/components/ui/card/card-title.svelte";
  import Badge from "$lib/components/ui/badge/badge.svelte";
  import {
    ArrowLeft,
    Search,
    CreditCard,
    Calendar,
    DollarSign,
    CheckCircle,
    XCircle,
    Clock,
    Filter,
  } from "lucide-svelte";

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

  function getStatusBadgeVariant(status) {
    switch (status) {
      case "confirmed":
        return "default";
      case "rejected":
        return "destructive";
      case "pending":
      default:
        return "secondary";
    }
  }

  function getStatusIcon(status) {
    switch (status) {
      case "confirmed":
        return CheckCircle;
      case "rejected":
        return XCircle;
      case "pending":
      default:
        return Clock;
    }
  }

  function goBack() {
    router.get("/dashboard");
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

<svelte:head>
  <title>My Payments - SplitSub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <button
          type="button"
          onclick={goBack}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Projects
        </button>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">My Payments</h1>
      <p class="text-muted-foreground text-lg">
        View and manage all your payment submissions
      </p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <CreditCard class="h-4 w-4 text-muted-foreground" />
            <div>
              <p class="text-2xl font-bold">{statusCounts.all}</p>
              <p class="text-xs text-muted-foreground">Total</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <Clock class="h-4 w-4 text-yellow-600" />
            <div>
              <p class="text-2xl font-bold">{statusCounts.pending}</p>
              <p class="text-xs text-muted-foreground">Pending</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <CheckCircle class="h-4 w-4 text-green-600" />
            <div>
              <p class="text-2xl font-bold">{statusCounts.confirmed}</p>
              <p class="text-xs text-muted-foreground">Confirmed</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent class="p-4">
          <div class="flex items-center gap-2">
            <XCircle class="h-4 w-4 text-red-600" />
            <div>
              <p class="text-2xl font-bold">{statusCounts.rejected}</p>
              <p class="text-xs text-muted-foreground">Rejected</p>
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
                placeholder="Search by project or transaction ID..."
                bind:value={searchTerm}
                class="pl-10"
              />
            </div>
          </div>

          <!-- Status Filter -->
          <select
            bind:value={filterStatus}
            class="px-3 py-2 border border-input bg-background rounded-md text-sm"
          >
            <option value="all">All Statuses ({statusCounts.all})</option>
            <option value="pending">Pending ({statusCounts.pending})</option>
            <option value="confirmed"
              >Confirmed ({statusCounts.confirmed})</option
            >
            <option value="rejected">Rejected ({statusCounts.rejected})</option>
          </select>
        </div>
      </CardContent>
    </Card>

    <!-- Payments List -->
    {#if filteredPayments.length === 0}
      <Card>
        <CardContent class="pt-6">
          <div class="text-center py-12">
            {#if payments.length === 0}
              <CreditCard class="mx-auto h-12 w-12 text-gray-400 mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                No payments yet
              </h3>
              <p class="text-gray-600 mb-4">
                You haven't submitted any payment evidence yet.
              </p>
              <Button onclick={() => router.visit("/dashboard")}>
                View Projects
              </Button>
            {:else}
              <Search class="mx-auto h-12 w-12 text-gray-400 mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                No payments found
              </h3>
              <p class="text-gray-600 mb-4">
                No payments match your current filters.
              </p>
              <Button
                variant="outline"
                onclick={() => {
                  filterStatus = "all";
                  searchTerm = "";
                }}
              >
                Clear Filters
              </Button>
            {/if}
          </div>
        </CardContent>
      </Card>
    {:else}
      <div class="space-y-4">
        {#each filteredPayments as payment}
          <Card class="hover:shadow-md transition-shadow cursor-pointer">
            <CardContent class="pt-6">
              <div
                class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4"
                onclick={() => viewPayment(payment.id)}
                onkeydown={(e) =>
                  (e.key === "Enter" || e.key === " ") &&
                  viewPayment(payment.id)}
                role="button"
                tabindex="0"
              >
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <svelte:component
                      this={getStatusIcon(payment.status)}
                      class="w-5 h-5 {payment.status === 'confirmed'
                        ? 'text-green-600'
                        : payment.status === 'rejected'
                          ? 'text-red-600'
                          : 'text-yellow-600'}"
                    />
                    <h3 class="text-lg font-semibold">
                      {payment.billing_cycle?.project?.name ||
                        "Unknown Project"}
                    </h3>
                    <Badge variant={getStatusBadgeVariant(payment.status)}>
                      {payment.status}
                    </Badge>
                  </div>

                  <div
                    class="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm text-gray-600"
                  >
                    <div>
                      <span class="font-medium">Amount:</span>
                      <div class="text-lg font-semibold text-gray-900">
                        {formatCurrency(payment.amount)}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Due Date:</span>
                      <div class="text-sm">
                        {payment.billing_cycle?.due_date
                          ? formatDate(payment.billing_cycle.due_date)
                          : "Unknown"}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Submitted:</span>
                      <div class="text-sm">
                        {formatDate(payment.created_at)}
                      </div>
                    </div>
                    {#if payment.confirmation_date}
                      <div>
                        <span class="font-medium">Confirmed:</span>
                        <div class="text-sm">
                          {formatDate(payment.confirmation_date)}
                        </div>
                      </div>
                    {/if}
                  </div>

                  <div class="mt-2 flex gap-4 text-sm">
                    {#if payment.has_evidence}
                      <span class="text-blue-600">📎 File attached</span>
                    {/if}
                    {#if payment.transaction_id}
                      <span class="text-gray-600">
                        ID: {payment.transaction_id}
                      </span>
                    {/if}
                    {#if !payment.has_evidence && !payment.transaction_id}
                      <span class="text-amber-600">⚠️ No evidence provided</span
                      >
                    {/if}
                  </div>
                </div>

                <div class="flex gap-2">
                  <Button variant="outline" size="sm">View Details</Button>
                </div>
              </div>
            </CardContent>
          </Card>
        {/each}
      </div>
    {/if}
  </div>
</Layout>
