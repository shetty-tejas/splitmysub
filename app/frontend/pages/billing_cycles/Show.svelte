<script>
  import { router } from "@inertiajs/svelte";
  import Layout from "../../layouts/layout.svelte";
  import Button from "$lib/components/ui/button/button.svelte";
  import Card from "$lib/components/ui/card/card.svelte";
  import CardContent from "$lib/components/ui/card/card-content.svelte";
  import CardHeader from "$lib/components/ui/card/card-header.svelte";
  import CardTitle from "$lib/components/ui/card/card-title.svelte";
  import Badge from "$lib/components/ui/badge/badge.svelte";
  import {
    ArrowLeft,
    Calendar,
    DollarSign,
    Users,
    CheckCircle,
    XCircle,
    Clock,
    AlertCircle,
    Download,
    Edit,
    Trash2,
  } from "lucide-svelte";
  import {
    formatCurrency,
    formatDate,
    formatDateTime,
    getPaymentStatusBadgeVariant,
    getPaymentStatusIcon,
    calculatePaymentProgress,
  } from "$lib/billing-utils";

  export let project;
  export let billing_cycle;
  export let payments;
  export let payment_stats;
  export let user_permissions;

  function getStatusIcon(status) {
    const iconName = getPaymentStatusIcon(status);
    switch (iconName) {
      case "CheckCircle":
        return CheckCircle;
      case "XCircle":
        return XCircle;
      case "Clock":
        return Clock;
      default:
        return AlertCircle;
    }
  }

  function deleteBillingCycle() {
    if (
      confirm(
        "Are you sure you want to delete this billing cycle? This action cannot be undone.",
      )
    ) {
      router.delete(
        `/projects/${project.slug}/billing_cycles/${billing_cycle.id}`,
      );
    }
  }

  function downloadEvidence(payment) {
    if (payment.evidence_url) {
      window.open(payment.evidence_url, "_blank");
    }
  }

  $: progressPercentage = calculatePaymentProgress(
    billing_cycle.total_paid,
    billing_cycle.total_amount,
  );
</script>

<svelte:head>
  <title
    >Billing Cycle - {formatDate(billing_cycle.due_date)} - {project.name} - SplitSub</title
  >
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <a
          href="/projects/{project.slug}/billing_cycles"
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Billing Cycles
        </a>
      </div>
      {#if user_permissions?.can_manage}
        <div class="flex gap-2">
          <Button
            href="/projects/{project.slug}/billing_cycles/{billing_cycle.id}/edit"
            variant="outline"
          >
            <Edit class="w-4 h-4 mr-2" />
            Edit
          </Button>
          <Button onclick={deleteBillingCycle} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (deleteBillingCycle)} variant="destructive">
            <Trash2 class="w-4 h-4 mr-2" />
            Delete
          </Button>
        </div>
      {/if}
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">
        Billing Cycle - {formatDate(billing_cycle.due_date)}
      </h1>
      <p class="text-muted-foreground text-lg">
        <strong>{project.name}</strong>
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
          You're viewing this billing cycle as a project member. Contact the
          project owner to make changes.
        </p>
      </div>
    {/if}

    <!-- Status Overview -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Due Date</CardTitle>
          <Calendar class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">
            {formatDate(billing_cycle.due_date)}
          </div>
          <p class="text-xs text-muted-foreground">
            {#if billing_cycle.overdue}
              <span class="text-red-600"
                >Overdue by {Math.abs(billing_cycle.days_until_due)} day{Math.abs(
                  billing_cycle.days_until_due,
                ) === 1
                  ? ""
                  : "s"}</span
              >
            {:else if billing_cycle.days_until_due === 0}
              <span class="text-orange-600">Due today</span>
            {:else}
              Due in {billing_cycle.days_until_due} day{billing_cycle.days_until_due ===
              1
                ? ""
                : "s"}
            {/if}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Total Amount</CardTitle>
          <DollarSign class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">
            {formatCurrency(billing_cycle.total_amount)}
          </div>
          <p class="text-xs text-muted-foreground">
            {formatCurrency(billing_cycle.expected_payment_per_member)} per member
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Amount Paid</CardTitle>
          <CheckCircle class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold text-green-600">
            {formatCurrency(billing_cycle.total_paid)}
          </div>
          <p class="text-xs text-muted-foreground">
            {progressPercentage.toFixed(1)}% of total
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Remaining</CardTitle>
          <AlertCircle class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold text-red-600">
            {formatCurrency(billing_cycle.amount_remaining)}
          </div>
          <p class="text-xs text-muted-foreground">
            {billing_cycle.members_who_havent_paid.length} member{billing_cycle
              .members_who_havent_paid.length === 1
              ? ""
              : "s"} pending
          </p>
        </CardContent>
      </Card>
    </div>

    <!-- Progress Bar -->
    <Card class="mb-8">
      <CardContent class="pt-6">
        <div class="space-y-2">
          <div class="flex justify-between text-sm">
            <span>Payment Progress</span>
            <span>{progressPercentage.toFixed(1)}%</span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2">
            <div
              class="bg-green-600 h-2 rounded-full transition-all duration-300"
              style="width: {progressPercentage}%"
            ></div>
          </div>
          <div class="flex justify-between text-xs text-gray-600">
            <span>{formatCurrency(billing_cycle.total_paid)} paid</span>
            <span
              >{formatCurrency(billing_cycle.amount_remaining)} remaining</span
            >
          </div>
        </div>
      </CardContent>
    </Card>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <!-- Members Who Paid -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <CheckCircle class="w-5 h-5 text-green-600" />
            Members Who Paid ({billing_cycle.members_who_paid.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {#if billing_cycle.members_who_paid.length === 0}
            <p class="text-gray-600 text-center py-4">
              No payments received yet
            </p>
          {:else}
            <div class="space-y-2">
              {#each billing_cycle.members_who_paid as member}
                <div
                  class="flex items-center justify-between p-3 bg-green-50 rounded-lg"
                >
                  <span class="font-medium">{member.email_address}</span>
                  <CheckCircle class="w-4 h-4 text-green-600" />
                </div>
              {/each}
            </div>
          {/if}
        </CardContent>
      </Card>

      <!-- Members Who Haven't Paid -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2">
            <XCircle class="w-5 h-5 text-red-600" />
            Members Who Haven't Paid ({billing_cycle.members_who_havent_paid
              .length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {#if billing_cycle.members_who_havent_paid.length === 0}
            <p class="text-green-600 text-center py-4 font-medium">
              All members have paid! 🎉
            </p>
          {:else}
            <div class="space-y-2">
              {#each billing_cycle.members_who_havent_paid as member}
                <div
                  class="flex items-center justify-between p-3 bg-red-50 rounded-lg"
                >
                  <span class="font-medium">{member.email_address}</span>
                  <XCircle class="w-4 h-4 text-red-600" />
                </div>
              {/each}
            </div>
          {/if}
        </CardContent>
      </Card>
    </div>

    <!-- Payment Details -->
    <Card class="mt-8">
      <CardHeader>
        <CardTitle class="flex items-center gap-2">
          <DollarSign class="w-5 h-5" />
          Payment Details ({payments.length})
        </CardTitle>
      </CardHeader>
      <CardContent>
        {#if payments.length === 0}
          <div class="text-center py-12">
            <DollarSign class="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              No payments yet
            </h3>
            <p class="text-gray-600">
              Payments will appear here as members submit them.
            </p>
          </div>
        {:else}
          <div class="space-y-4">
            {#each payments as payment}
              <div class="border rounded-lg p-4">
                <div
                  class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4"
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
                      <span class="font-semibold"
                        >{payment.user.email_address}</span
                      >
                      <Badge
                        variant={getPaymentStatusBadgeVariant(payment.status)}
                      >
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
                        <span class="font-medium">Submitted:</span>
                        <div class="text-sm">
                          {formatDateTime(payment.created_at)}
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
                      {#if payment.transaction_id}
                        <div>
                          <span class="font-medium">Transaction ID:</span>
                          <div class="text-sm font-mono">
                            {payment.transaction_id}
                          </div>
                        </div>
                      {/if}
                    </div>

                    {#if payment.notes}
                      <div class="mt-2">
                        <span class="text-sm font-medium text-gray-600"
                          >Notes:</span
                        >
                        <p class="text-sm text-gray-700 mt-1">
                          {payment.notes}
                        </p>
                      </div>
                    {/if}
                  </div>

                  <div class="flex gap-2">
                    {#if payment.has_evidence}
                      <Button
                        onclick={() => downloadEvidence(payment)} onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && (() => downloadEvidence(payment))}
                        variant="outline"
                        size="sm"
                      >
                        <Download class="w-4 h-4 mr-2" />
                        Evidence
                      </Button>
                    {/if}
                    <Button
                      href="/payments/{payment.id}"
                      variant="outline"
                      size="sm"
                    >
                      View Details
                    </Button>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </CardContent>
    </Card>

    <!-- Payment Statistics -->
    <Card class="mt-8">
      <CardHeader>
        <CardTitle>Payment Statistics</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
          <div class="text-center">
            <div class="text-2xl font-bold text-gray-900">
              {payment_stats.total}
            </div>
            <div class="text-sm text-gray-600">Total</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-yellow-600">
              {payment_stats.pending}
            </div>
            <div class="text-sm text-gray-600">Pending</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-green-600">
              {payment_stats.confirmed}
            </div>
            <div class="text-sm text-gray-600">Confirmed</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-red-600">
              {payment_stats.rejected}
            </div>
            <div class="text-sm text-gray-600">Rejected</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-blue-600">
              {payment_stats.with_evidence}
            </div>
            <div class="text-sm text-gray-600">With Evidence</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-gray-600">
              {payment_stats.without_evidence}
            </div>
            <div class="text-sm text-gray-600">No Evidence</div>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</Layout>
