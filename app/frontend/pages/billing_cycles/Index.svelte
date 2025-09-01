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
    Search,
    Plus,
    Calendar,
    DollarSign,
    AlertCircle,
    CheckCircle,
    Clock,
    ArrowLeft,
  } from "@lucide/svelte";
  import {
    formatCurrency,
    formatDate,
    getPaymentStatusBadgeVariant,
    getBillingCycleStatusColor,
  } from "$lib/billing-utils";
  import { FILTER_OPTIONS, SORT_OPTIONS } from "$lib/billing-constants";

  export let project;
  export let billing_cycles;
  export let stats;
  export let filters;
  export let user_permissions;

  // Provide a default stats object if stats is undefined or doesn't have expected properties
  $: safeStats =
    stats && typeof stats === "object" && "total_amount" in stats
      ? stats
      : {
          total: 0,
          active: 0,
          archived: 0,
          upcoming: 0,
          overdue: 0,
          due_soon: 0,
          fully_paid: 0,
          partially_paid: 0,
          unpaid: 0,
          adjusted: 0,
          archivable: 0,
          total_amount: 0,
          total_paid: 0,
          total_remaining: 0,
        };

  let searchTerm = filters.search || "";
  let selectedFilter = filters.filter || FILTER_OPTIONS.ALL;
  let selectedSort = filters.sort || SORT_OPTIONS.DUE_DATE_DESC;

  function handleSearch() {
    router.get(
      `/projects/${project.slug}/billing_cycles`,
      {
        search: searchTerm,
        filter: selectedFilter,
        sort: selectedSort,
      },
      {
        preserveState: true,
        replace: true,
      },
    );
  }

  function handleFilterChange() {
    router.get(
      `/projects/${project.slug}/billing_cycles`,
      {
        search: searchTerm,
        filter: selectedFilter,
        sort: selectedSort,
      },
      {
        preserveState: true,
        replace: true,
      },
    );
  }

  function generateUpcomingCycles() {
    router.post(
      `/projects/${project.slug}/billing_cycles/generate_upcoming`,
      {},
      {
        preserveState: false,
      },
    );
  }

  function getStatusIcon(cycle) {
    if (cycle.fully_paid) return CheckCircle;
    if (cycle.overdue) return AlertCircle;
    return Clock;
  }

  function goBack() {
    router.get(`/projects/${project.slug}`);
  }
</script>

<svelte:head>
  <title>Billing Cycles - {project.name} - SplitMySub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div class="flex items-center gap-4">
        <button
          type="button"
          onclick={goBack}
          onkeydown={(e) => (e.key === "Enter" || e.key === " ") && goBack}
          class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
        >
          <ArrowLeft class="h-4 w-4" />
          Back to Project
        </button>
      </div>
    </div>

    <!-- Project Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold tracking-tight mb-2">Billing Cycles</h1>
      <div class="space-y-2">
        <p class="text-muted-foreground text-lg">
          Manage billing cycles for <strong>{project.name}</strong>
        </p>
        <p class="text-sm text-muted-foreground">
          Track recurring subscription payments, monitor due dates, and manage
          member contributions. Each billing cycle represents a payment period
          where members can submit their portion of shared costs.
          {#if user_permissions?.can_manage}
            As a project owner, you can create new cycles, generate upcoming
            periods, and review payment submissions.
          {:else if user_permissions?.is_member}
            As a project member, you can view billing cycles and submit payment
            evidence when due.
          {/if}
        </p>
      </div>
    </div>

    <!-- Action Buttons - Only for owners -->
    {#if user_permissions?.can_manage}
      <div class="flex flex-col sm:flex-row gap-2 mb-8">
        <Button
          onclick={generateUpcomingCycles}
          onkeydown={(e) =>
            (e.key === "Enter" || e.key === " ") && generateUpcomingCycles}
          variant="outline"
        >
          <Calendar class="w-4 h-4 mr-2" />
          Generate Upcoming
        </Button>
        <Button href="/projects/{project.slug}/billing_cycles/new">
          <Plus class="w-4 h-4 mr-2" />
          New Billing Cycle
        </Button>
      </div>
    {:else if user_permissions?.is_member}
      <!-- Member view notice -->
      <div class="mb-8 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <div class="flex items-center gap-2 text-blue-800">
          <AlertCircle class="h-4 w-4" />
          <span class="text-sm font-medium">Member View</span>
        </div>
        <p class="text-sm text-blue-700 mt-1">
          You're viewing billing cycles as a project member. Contact the project
          owner to make changes.
        </p>
      </div>
    {/if}

    <!-- Quick Info -->
    <Card class="mb-6 border-l-4 border-l-green-500 bg-green-50/50">
      <CardContent class="pt-6">
        <div class="flex items-start gap-3">
          <div class="mt-0.5">
            <Calendar class="h-5 w-5 text-green-600" />
          </div>
          <div>
            <h3 class="font-medium text-green-900 mb-1">
              How Billing Cycles Work
            </h3>
            <div class="text-sm text-green-800 space-y-1">
              <p><strong>Upcoming:</strong> Cycles ready for member payments</p>
              <p>
                <strong>Due Soon:</strong> Payment deadlines approaching within 3
                days
              </p>
              <p>
                <strong>Overdue:</strong> Past due date - members should submit payments
                urgently
              </p>
              <p>
                <strong>Fully Paid:</strong> All members have contributed their share
              </p>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Total Cycles</CardTitle>
          <Calendar class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">{safeStats.total}</div>
          <p class="text-xs text-muted-foreground">
            {safeStats.upcoming} upcoming, {safeStats.overdue} overdue
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Collected Amount</CardTitle>
          <DollarSign class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold">
            {formatCurrency(safeStats.total_paid, project.currency)}
          </div>
          <p class="text-xs text-muted-foreground">
            of total {formatCurrency(safeStats.total_amount, project.currency)} to date
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Payment Status</CardTitle>
          <CheckCircle class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold text-green-600">
            {safeStats.fully_paid}
          </div>
          <p class="text-xs text-muted-foreground">
            {safeStats.partially_paid} partial, {safeStats.unpaid} unpaid
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader
          class="flex flex-row items-center justify-between space-y-0 pb-2"
        >
          <CardTitle class="text-sm font-medium">Outstanding</CardTitle>
          <AlertCircle class="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div class="text-2xl font-bold text-red-600">
            {formatCurrency(safeStats.total_remaining, project.currency)}
          </div>
          <p class="text-xs text-muted-foreground">
            {safeStats.due_soon} due soon, {safeStats.overdue} overdue
          </p>
        </CardContent>
      </Card>
    </div>

    <!-- Filters and Search -->
    <Card class="mb-6">
      <CardContent class="pt-6">
        <div class="flex flex-col sm:flex-row gap-4">
          <!-- Search -->
          <div class="flex-1">
            <div class="relative">
              <Search
                class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4"
              />
              <Input
                bind:value={searchTerm}
                placeholder="Search by amount..."
                class="pl-10"
                onkeydown={(e) => e.key === "Enter" && handleSearch()}
              />
            </div>
          </div>

          <!-- Filter -->
          <select
            bind:value={selectedFilter}
            onchange={handleFilterChange}
            class="flex h-9 w-full sm:w-48 items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value={FILTER_OPTIONS.ALL}>All Cycles</option>
            <option value={FILTER_OPTIONS.UPCOMING}>Upcoming</option>
            <option value={FILTER_OPTIONS.OVERDUE}>Overdue</option>
            <option value={FILTER_OPTIONS.DUE_SOON}>Due Soon</option>
          </select>

          <!-- Sort -->
          <select
            bind:value={selectedSort}
            onchange={handleFilterChange}
            class="flex h-9 w-full sm:w-48 items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value={SORT_OPTIONS.DUE_DATE_DESC}>Due Date (Newest)</option
            >
            <option value={SORT_OPTIONS.DUE_DATE_ASC}>Due Date (Oldest)</option>
            <option value={SORT_OPTIONS.AMOUNT_DESC}
              >Amount (High to Low)</option
            >
            <option value={SORT_OPTIONS.AMOUNT_ASC}>Amount (Low to High)</option
            >
          </select>

          <Button
            onclick={handleSearch}
            onkeydown={(e) =>
              (e.key === "Enter" || e.key === " ") && handleSearch}
            variant="outline"
          >
            <Search class="w-4 h-4 mr-2" />
            Search
          </Button>
        </div>
      </CardContent>
    </Card>

    <!-- Billing Cycles List -->
    {#if billing_cycles.length === 0}
      <Card>
        <CardContent class="pt-6">
          <div class="text-center py-12">
            <Calendar class="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              No billing cycles found
            </h3>
            <p class="text-gray-600 mb-4">
              {#if filters.search || filters.filter !== FILTER_OPTIONS.ALL}
                Try adjusting your search or filter criteria.
              {:else}
                Get started by creating your first billing cycle.
              {/if}
            </p>
            {#if !filters.search && filters.filter === FILTER_OPTIONS.ALL}
              <Button href="/projects/{project.slug}/billing_cycles/new">
                <Plus class="w-4 h-4 mr-2" />
                Create Billing Cycle
              </Button>
            {/if}
          </div>
        </CardContent>
      </Card>
    {:else}
      <div class="space-y-4">
        {#each billing_cycles as cycle}
          <Card class="hover:shadow-md transition-shadow">
            <CardContent class="pt-6">
              <div
                class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4"
              >
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <svelte:component
                      this={getStatusIcon(cycle)}
                      class="w-5 h-5 {getBillingCycleStatusColor(cycle)}"
                    />
                    <h3 class="text-lg font-semibold">
                      Due {formatDate(cycle.due_date)}
                    </h3>
                    <Badge
                      variant={getPaymentStatusBadgeVariant(
                        cycle.payment_status,
                      )}
                    >
                      {cycle.payment_status}
                    </Badge>
                    {#if cycle.overdue}
                      <Badge variant="destructive">Overdue</Badge>
                    {:else if cycle.due_soon}
                      <Badge variant="secondary">Due Soon</Badge>
                    {/if}
                  </div>

                  <div
                    class="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm text-gray-600"
                  >
                    <div>
                      <span class="font-medium">Total Amount:</span>
                      <div class="text-lg font-semibold text-gray-900">
                        {formatCurrency(cycle.total_amount, project.currency)}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Paid:</span>
                      <div class="text-lg font-semibold text-green-600">
                        {formatCurrency(cycle.total_paid, project.currency)}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Remaining:</span>
                      <div class="text-lg font-semibold text-red-600">
                        {formatCurrency(
                          cycle.amount_remaining,
                          project.currency,
                        )}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Payments:</span>
                      <div class="text-lg font-semibold text-gray-900">
                        {cycle.payments_count}
                      </div>
                    </div>
                  </div>

                  {#if cycle.days_until_due !== undefined}
                    <div class="mt-2 text-sm">
                      {#if cycle.fully_paid}
                          <span class="text-gray-600">
                            Settled - no payment due 🎉
                          </span>
                      {:else}
                        {#if cycle.overdue}
                          <span class="text-red-600 font-medium">
                            Overdue by {Math.abs(cycle.days_until_due)} day{Math.abs(
                              cycle.days_until_due,
                            ) === 1
                              ? ""
                              : "s"}
                          </span>
                        {:else if cycle.days_until_due === 0}
                          <span class="text-orange-600 font-medium"
                            >Due today</span
                          >
                        {:else}
                          <span class="text-gray-600">
                            Due in {cycle.days_until_due} day{cycle.days_until_due ===
                            1
                              ? ""
                              : "s"}
                          </span>
                        {/if}
                      {/if}
                    </div>
                  {/if}
                </div>

                <div class="flex flex-col gap-2">
                  {#if cycle.can_pay}
                    <Button href="/billing_cycles/{cycle.id}/payments/new"
                      variant="default"
                      size="sm" >
                      Submit Proof
                    </Button>
                  {/if}
                  <Button
                    href="/projects/{project.slug}/billing_cycles/{cycle.id}"
                    variant="outline"
                    size="sm"
                  >
                    View Details
                  </Button>
                  {#if project.is_owner}
                    <Button
                      href="/projects/{project.slug}/billing_cycles/{cycle.id}/edit"
                      variant="outline"
                      size="sm"
                    >
                      Edit
                    </Button>
                  {/if}
                </div>
              </div>
            </CardContent>
          </Card>
        {/each}
      </div>
    {/if}
  </div>
</Layout>
