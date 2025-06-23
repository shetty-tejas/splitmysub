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
    AlertCircle,
    Eye,
    Download,
  } from "lucide-svelte";

  export let project;
  export let payments;
  export let user_permissions;

  let filterStatus = "all";
  let searchTerm = "";

  $: filteredPayments = payments.filter((payment) => {
    const matchesStatus =
      filterStatus === "all" || payment.status === filterStatus;
    const matchesSearch =
      searchTerm === "" ||
      payment.user?.email_address
        ?.toLowerCase()
        .includes(searchTerm.toLowerCase()) ||
      payment.transaction_id
        ?.toLowerCase()
        .includes(searchTerm.toLowerCase()) ||
      payment.notes?.toLowerCase().includes(searchTerm.toLowerCase());

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
    router.get(`/projects/${project.slug}`);
  }

  function viewPayment(paymentId) {
    router.visit(`/payments/${paymentId}`);
  }

  function downloadEvidence(paymentId) {
    window.open(`/secure_files/payment_evidence/${paymentId}`, "_blank");
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
  <title>Payments - {project.name} - SplitSub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <button
          type="button"
          onclick={goBack} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (goBack)}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Project
        </button>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">Project Payments</h1>
      <p class="text-muted-foreground text-lg">
        View all payments for <strong>{project.name}</strong>
      </p>
    </div>

    <!-- Member view notice -->
    {#if user_permissions?.is_member && !user_permissions?.is_owner}
      <div class="mb-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="flex items-center gap-2 text-blue-800">
          <AlertCircle class="h-4 w-4" />
          <span class="text-sm font-medium">Member View</span>
        </div>
        <p class="text-sm text-blue-700 mt-1">
          You're viewing project payments as a member. You can see all payment
          statuses but cannot modify them.
        </p>
      </div>
    {/if}

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
                placeholder="Search by member email, transaction ID, or notes..."
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
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="confirmed">Confirmed</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>
      </CardContent>
    </Card>

    <!-- Payments List -->
    {#if filteredPayments.length > 0}
      <div class="space-y-4">
        {#each filteredPayments as payment}
          <Card class="hover:shadow-md transition-shadow">
            <CardContent class="p-6">
              <div
                class="flex flex-col lg:flex-row lg:items-center justify-between gap-4"
              >
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <svelte:component
                      this={getStatusIcon(payment.status)}
                      class="h-5 w-5 {payment.status === 'confirmed'
                        ? 'text-green-600'
                        : payment.status === 'rejected'
                          ? 'text-red-600'
                          : 'text-yellow-600'}"
                    />
                    <div>
                      <h3 class="font-semibold text-lg">
                        {formatCurrency(payment.amount)}
                      </h3>
                      <p class="text-sm text-muted-foreground">
                        by {payment.user?.email_address || "Unknown User"}
                      </p>
                    </div>
                    <Badge variant={getStatusBadgeVariant(payment.status)}>
                      {payment.status}
                    </Badge>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="text-muted-foreground">Due Date:</span>
                      <span class="ml-2 font-medium">
                        {formatDate(payment.billing_cycle?.due_date)}
                      </span>
                    </div>
                    <div>
                      <span class="text-muted-foreground">Submitted:</span>
                      <span class="ml-2 font-medium">
                        {formatDate(payment.created_at)}
                      </span>
                    </div>
                    {#if payment.transaction_id}
                      <div>
                        <span class="text-muted-foreground"
                          >Transaction ID:</span
                        >
                        <span class="ml-2 font-medium font-mono text-xs">
                          {payment.transaction_id}
                        </span>
                      </div>
                    {/if}
                    {#if payment.confirmation_date}
                      <div>
                        <span class="text-muted-foreground">Confirmed:</span>
                        <span class="ml-2 font-medium">
                          {formatDate(payment.confirmation_date)}
                        </span>
                      </div>
                    {/if}
                  </div>

                  {#if payment.notes}
                    <div class="mt-3 p-3 bg-muted rounded-md">
                      <p class="text-sm">{payment.notes}</p>
                    </div>
                  {/if}

                  {#if payment.confirmation_notes}
                    <div
                      class="mt-3 p-3 bg-green-50 border border-green-200 rounded-md"
                    >
                      <p class="text-sm text-green-800">
                        <strong>Confirmation Notes:</strong>
                        {payment.confirmation_notes}
                      </p>
                    </div>
                  {/if}

                  {#if payment.dispute_reason}
                    <div
                      class="mt-3 p-3 bg-red-50 border border-red-200 rounded-md"
                    >
                      <p class="text-sm text-red-800">
                        <strong>Dispute Reason:</strong>
                        {payment.dispute_reason}
                      </p>
                    </div>
                  {/if}
                </div>

                <div class="flex flex-col sm:flex-row gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onclick={() => viewPayment(payment.id)} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => viewPayment(payment.id))}
                  >
                    <Eye class="h-4 w-4 mr-2" />
                    View Details
                  </Button>
                  {#if payment.has_evidence}
                    <Button
                      variant="outline"
                      size="sm"
                      onclick={() => downloadEvidence(payment.id)} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => downloadEvidence(payment.id))}
                    >
                      <Download class="h-4 w-4 mr-2" />
                      Evidence
                    </Button>
                  {/if}
                </div>
              </div>
            </CardContent>
          </Card>
        {/each}
      </div>
    {:else}
      <Card class="text-center py-12">
        <CardContent>
          <div class="flex flex-col items-center gap-4">
            <div class="rounded-full bg-muted p-4">
              <CreditCard class="h-8 w-8 text-muted-foreground" />
            </div>
            <div>
              <h3 class="text-lg font-semibold">No payments found</h3>
              <p class="text-muted-foreground">
                {searchTerm || filterStatus !== "all"
                  ? "No payments match your current filters"
                  : "No payment submissions yet for this project"}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    {/if}
  </div>
</Layout>
