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
    Users,
    AlertCircle,
    CheckCircle,
    Clock,
    ArrowLeft,
  } from "lucide-svelte";

  export let project;
  export let billing_cycles;
  export let stats;
  export let filters;

  let searchTerm = filters.search || "";
  let selectedFilter = filters.filter || "all";
  let selectedSort = filters.sort || "due_date_desc";

  function handleSearch() {
    router.get(
      `/projects/${project.id}/billing_cycles`,
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
      `/projects/${project.id}/billing_cycles`,
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
      `/projects/${project.id}/billing_cycles/generate_upcoming`,
      {},
      {
        preserveState: false,
      },
    );
  }

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function getStatusBadgeVariant(status) {
    switch (status) {
      case "paid":
        return "default";
      case "partial":
        return "secondary";
      case "unpaid":
        return "destructive";
      default:
        return "outline";
    }
  }

  function getStatusIcon(cycle) {
    if (cycle.fully_paid) return CheckCircle;
    if (cycle.overdue) return AlertCircle;
    return Clock;
  }

  function getStatusColor(cycle) {
    if (cycle.fully_paid) return "text-green-600";
    if (cycle.overdue) return "text-red-600";
    return "text-yellow-600";
  }

  function goBack() {
    router.get(`/projects/${project.id}`);
  }
</script>

<svelte:head>
  <title>Billing Cycles - {project.name}</title>
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
      <h1 class="text-3xl font-bold tracking-tight mb-2">Billing Cycles</h1>
      <p class="text-muted-foreground text-lg">
        Manage billing cycles for <strong>{project.name}</strong>
      </p>
    </div>

    <!-- Action Buttons -->
    <div class="flex flex-col sm:flex-row gap-2 mb-8">
      <Button on:click={generateUpcomingCycles} variant="outline">
        <Calendar class="w-4 h-4 mr-2" />
        Generate Upcoming
      </Button>
      <Button href="/projects/{project.id}/billing_cycles/new">
        <Plus class="w-4 h-4 mr-2" />
        New Billing Cycle
      </Button>
    </div>

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
          <div class="text-2xl font-bold">{stats.total}</div>
          <p class="text-xs text-muted-foreground">
            {stats.upcoming} upcoming, {stats.overdue} overdue
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
            {formatCurrency(stats.total_amount)}
          </div>
          <p class="text-xs text-muted-foreground">
            {formatCurrency(stats.total_paid)} collected
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
            {stats.fully_paid}
          </div>
          <p class="text-xs text-muted-foreground">
            {stats.partially_paid} partial, {stats.unpaid} unpaid
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
            {formatCurrency(stats.total_remaining)}
          </div>
          <p class="text-xs text-muted-foreground">
            {stats.due_soon} due soon
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
                on:keydown={(e) => e.key === "Enter" && handleSearch()}
              />
            </div>
          </div>

          <!-- Filter -->
          <select
            bind:value={selectedFilter}
            on:change={handleFilterChange}
            class="flex h-9 w-full sm:w-48 items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value="all">All Cycles</option>
            <option value="upcoming">Upcoming</option>
            <option value="overdue">Overdue</option>
            <option value="due_soon">Due Soon</option>
          </select>

          <!-- Sort -->
          <select
            bind:value={selectedSort}
            on:change={handleFilterChange}
            class="flex h-9 w-full sm:w-48 items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
          >
            <option value="due_date_desc">Due Date (Newest)</option>
            <option value="due_date_asc">Due Date (Oldest)</option>
            <option value="amount_desc">Amount (High to Low)</option>
            <option value="amount_asc">Amount (Low to High)</option>
          </select>

          <Button on:click={handleSearch} variant="outline">
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
              {#if filters.search || filters.filter !== "all"}
                Try adjusting your search or filter criteria.
              {:else}
                Get started by creating your first billing cycle.
              {/if}
            </p>
            {#if !filters.search && filters.filter === "all"}
              <Button href="/projects/{project.id}/billing_cycles/new">
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
                      class="w-5 h-5 {getStatusColor(cycle)}"
                    />
                    <h3 class="text-lg font-semibold">
                      Due {formatDate(cycle.due_date)}
                    </h3>
                    <Badge
                      variant={getStatusBadgeVariant(cycle.payment_status)}
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
                        {formatCurrency(cycle.total_amount)}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Paid:</span>
                      <div class="text-lg font-semibold text-green-600">
                        {formatCurrency(cycle.total_paid)}
                      </div>
                    </div>
                    <div>
                      <span class="font-medium">Remaining:</span>
                      <div class="text-lg font-semibold text-red-600">
                        {formatCurrency(cycle.amount_remaining)}
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
                    </div>
                  {/if}
                </div>

                <div class="flex gap-2">
                  <Button
                    href="/projects/{project.id}/billing_cycles/{cycle.id}"
                    variant="outline"
                    size="sm"
                  >
                    View Details
                  </Button>
                  {#if project.is_owner}
                    <Button
                      href="/projects/{project.id}/billing_cycles/{cycle.id}/edit"
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
