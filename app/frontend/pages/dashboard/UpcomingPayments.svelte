<script>
  import Layout from "../../layouts/layout.svelte";
  import * as Card from "$lib/components/ui/card/index.js";
  import { Button } from "$lib/components/ui/button/index.js";
  import { Badge } from "$lib/components/ui/badge/index.js";
  import { Link } from "@inertiajs/svelte";
  import {
    ArrowLeft,
    Calendar,
    Clock,
    AlertTriangle,
    DollarSign,
    Users,
    Eye,
    CreditCard,
  } from "lucide-svelte";

  export let upcoming_cycles = [];
  export let calendar_data = {};

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  }

  function formatMonthYear(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
    });
  }

  function getDaysUntilDueColor(days) {
    if (days < 0) return "text-red-600";
    if (days <= 3) return "text-orange-600";
    if (days <= 7) return "text-yellow-600";
    return "text-green-600";
  }

  function getUrgencyColor(days) {
    if (days < 0) return "border-red-200 bg-red-50";
    if (days <= 3) return "border-orange-200 bg-orange-50";
    if (days <= 7) return "border-yellow-200 bg-yellow-50";
    return "border-gray-200 bg-white";
  }

  function getPaymentStatusColor(status) {
    switch (status) {
      case "confirmed":
        return "bg-green-100 text-green-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      case "unpaid":
        return "bg-gray-100 text-gray-800";
      case "overdue":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  }

  // Group upcoming cycles by urgency
  $: overduePayments = upcoming_cycles.filter(
    (cycle) => cycle.days_until_due < 0,
  );
  $: dueSoon = upcoming_cycles.filter(
    (cycle) => cycle.days_until_due >= 0 && cycle.days_until_due <= 7,
  );
  $: upcoming = upcoming_cycles.filter((cycle) => cycle.days_until_due > 7);

  // Calculate totals
  $: totalUpcoming = upcoming_cycles.reduce(
    (sum, cycle) => sum + (cycle.expected_payment || 0),
    0,
  );
  $: totalOverdue = overduePayments.reduce(
    (sum, cycle) => sum + (cycle.expected_payment || 0),
    0,
  );
</script>

<svelte:head>
  <title>Upcoming Payments - SplitSub</title>
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
      <h1 class="text-3xl font-bold text-gray-900">Upcoming Payments</h1>
      <p class="mt-2 text-gray-600">
        Stay on top of your subscription payment schedule
      </p>
    </div>

    <!-- Summary Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <AlertTriangle class="h-8 w-8 text-red-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Overdue</p>
              <p class="text-2xl font-bold text-gray-900">
                {overduePayments.length}
              </p>
              <p class="text-xs text-red-600">{formatCurrency(totalOverdue)}</p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <Clock class="h-8 w-8 text-orange-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Due Soon</p>
              <p class="text-2xl font-bold text-gray-900">{dueSoon.length}</p>
              <p class="text-xs text-orange-600">Next 7 days</p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <DollarSign class="h-8 w-8 text-green-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Total Upcoming</p>
              <p class="text-2xl font-bold text-gray-900">
                {formatCurrency(totalUpcoming)}
              </p>
              <p class="text-xs text-gray-500">
                {upcoming_cycles.length} payments
              </p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>
    </div>

    <!-- Overdue Payments (if any) -->
    {#if overduePayments.length > 0}
      <Card.Root class="mb-8 border-red-200">
        <Card.Header>
          <Card.Title class="flex items-center gap-2 text-red-700">
            <AlertTriangle class="h-5 w-5" />
            Overdue Payments
          </Card.Title>
        </Card.Header>
        <Card.Content>
          <div class="space-y-4">
            {#each overduePayments as cycle}
              <div class="border border-red-200 rounded-lg p-4 bg-red-50">
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-4">
                    <div class="flex-shrink-0">
                      <AlertTriangle class="h-6 w-6 text-red-600" />
                    </div>
                    <div>
                      <h3 class="text-lg font-medium text-gray-900">
                        {cycle.project.name}
                      </h3>
                      <p class="text-sm text-gray-600">
                        Due: {formatDate(cycle.due_date)} •
                        <span class="text-red-600 font-medium">
                          {Math.abs(cycle.days_until_due)} days overdue
                        </span>
                      </p>
                      <div class="flex items-center gap-2 mt-1">
                        <Users class="h-4 w-4 text-gray-400" />
                        <span class="text-sm text-gray-500">
                          {cycle.project.is_owner ? "Project Owner" : "Member"}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-xl font-bold text-gray-900">
                      {formatCurrency(cycle.expected_payment)}
                    </p>
                    <Badge
                      class={getPaymentStatusColor(cycle.user_payment_status)}
                    >
                      {cycle.user_payment_status}
                    </Badge>
                    <div class="flex gap-2 mt-2">
                      <Link href="/projects/{cycle.project.id}">
                        <Button variant="outline" size="sm">
                          <Eye class="h-3 w-3 mr-1" />
                          View
                        </Button>
                      </Link>
                      {#if cycle.user_payment_status === "unpaid"}
                        <Link href="/billing_cycles/{cycle.id}/payments/new">
                          <Button size="sm">
                            <CreditCard class="h-3 w-3 mr-1" />
                            Pay Now
                          </Button>
                        </Link>
                      {/if}
                    </div>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        </Card.Content>
      </Card.Root>
    {/if}

    <!-- Due Soon -->
    {#if dueSoon.length > 0}
      <Card.Root class="mb-8 border-orange-200">
        <Card.Header>
          <Card.Title class="flex items-center gap-2 text-orange-700">
            <Clock class="h-5 w-5" />
            Due Soon (Next 7 Days)
          </Card.Title>
        </Card.Header>
        <Card.Content>
          <div class="space-y-4">
            {#each dueSoon as cycle}
              <div class="border border-orange-200 rounded-lg p-4 bg-orange-50">
                <div class="flex items-center justify-between">
                  <div class="flex items-center space-x-4">
                    <div class="flex-shrink-0">
                      <Clock class="h-6 w-6 text-orange-600" />
                    </div>
                    <div>
                      <h3 class="text-lg font-medium text-gray-900">
                        {cycle.project.name}
                      </h3>
                      <p class="text-sm text-gray-600">
                        Due: {formatDate(cycle.due_date)} •
                        <span class="text-orange-600 font-medium">
                          {#if cycle.days_until_due === 0}
                            Due today
                          {:else}
                            {cycle.days_until_due} days left
                          {/if}
                        </span>
                      </p>
                      <div class="flex items-center gap-2 mt-1">
                        <Users class="h-4 w-4 text-gray-400" />
                        <span class="text-sm text-gray-500">
                          {cycle.project.is_owner ? "Project Owner" : "Member"}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-xl font-bold text-gray-900">
                      {formatCurrency(cycle.expected_payment)}
                    </p>
                    <Badge
                      class={getPaymentStatusColor(cycle.user_payment_status)}
                    >
                      {cycle.user_payment_status}
                    </Badge>
                    <div class="flex gap-2 mt-2">
                      <Link href="/projects/{cycle.project.id}">
                        <Button variant="outline" size="sm">
                          <Eye class="h-3 w-3 mr-1" />
                          View
                        </Button>
                      </Link>
                      {#if cycle.user_payment_status === "unpaid"}
                        <Link href="/billing_cycles/{cycle.id}/payments/new">
                          <Button size="sm">
                            <CreditCard class="h-3 w-3 mr-1" />
                            Pay Now
                          </Button>
                        </Link>
                      {/if}
                    </div>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        </Card.Content>
      </Card.Root>
    {/if}

    <!-- Calendar View -->
    <Card.Root>
      <Card.Header>
        <Card.Title class="flex items-center gap-2">
          <Calendar class="h-5 w-5" />
          Payment Calendar
        </Card.Title>
      </Card.Header>
      <Card.Content>
        {#if Object.keys(calendar_data).length > 0}
          <div class="space-y-8">
            {#each Object.entries(calendar_data) as [month, cycles]}
              <div>
                <h3 class="text-lg font-medium text-gray-900 mb-4">
                  {formatMonthYear(month)}
                </h3>
                <div
                  class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
                >
                  {#each cycles as cycle}
                    <div
                      class="border rounded-lg p-4 {getUrgencyColor(
                        cycle.days_until_due,
                      )} hover:shadow-md transition-shadow"
                    >
                      <div class="flex items-center justify-between mb-2">
                        <h4 class="font-medium text-gray-900">
                          {cycle.project.name}
                        </h4>
                        <Badge
                          class={getPaymentStatusColor(
                            cycle.user_payment_status,
                          )}
                        >
                          {cycle.user_payment_status}
                        </Badge>
                      </div>
                      <p class="text-sm text-gray-600 mb-2">
                        Due: {formatDate(cycle.due_date)}
                      </p>
                      <p class="text-lg font-bold text-gray-900 mb-2">
                        {formatCurrency(cycle.expected_payment)}
                      </p>
                      <p
                        class="text-xs {getDaysUntilDueColor(
                          cycle.days_until_due,
                        )} mb-3"
                      >
                        {#if cycle.days_until_due < 0}
                          {Math.abs(cycle.days_until_due)} days overdue
                        {:else if cycle.days_until_due === 0}
                          Due today
                        {:else}
                          {cycle.days_until_due} days left
                        {/if}
                      </p>
                      <div class="flex gap-2">
                        <Link href="/projects/{cycle.project.id}">
                          <Button variant="outline" size="sm" class="flex-1">
                            <Eye class="h-3 w-3 mr-1" />
                            View
                          </Button>
                        </Link>
                        {#if cycle.user_payment_status === "unpaid"}
                          <Link href="/billing_cycles/{cycle.id}/payments/new">
                            <Button size="sm" class="flex-1">
                              <CreditCard class="h-3 w-3 mr-1" />
                              Pay
                            </Button>
                          </Link>
                        {/if}
                      </div>
                    </div>
                  {/each}
                </div>
              </div>
            {/each}
          </div>
        {:else}
          <div class="text-center py-12">
            <Calendar class="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              No upcoming payments
            </h3>
            <p class="text-gray-500 mb-6">
              You're all caught up! No payments are due in the near future.
            </p>
            <Link href="/projects">
              <Button>Browse Projects</Button>
            </Link>
          </div>
        {/if}
      </Card.Content>
    </Card.Root>
  </div>
</Layout>
